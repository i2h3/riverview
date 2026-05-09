// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import Rivers
import SwiftUI
import UniformTypeIdentifiers

///
/// Top-level layout: a three-column `NavigationSplitView` with `FilterSidebar` on the left, the active view mode in the centre, and `MessageInspector` on the right. Owned by `RiverviewApp`'s `WindowGroup`.
///
/// All cross-view state — the journal store, the current selection, the time-range filter, the sidebar/inspector visibility, and the picked view mode — lives here as `@State` and is published through `.focusedSceneValue(...)` so menu commands in `RiverviewApp` can act on the focused window. Match-navigation menu items post `.riverviewNextMatch` / `.riverviewPreviousMatch` notifications, which this view translates into `selection` updates over `store.matchingEntries`.
///
struct ContentView: View {
    ///
    /// The journal currently being displayed. Owned by `RiverviewApp`; passed in here so this view holds no journal state of its own.
    ///
    @Bindable
    var store: JournalStore

    ///
    /// Which view mode is currently active. Driven by both the toolbar segmented picker and the View ▸ View Mode menu (which reads this through the focused scene value bridge).
    ///
    @State
    private var mode: ViewMode = .outline

    ///
    /// The currently selected entry across all view modes and the inspector. Using a single shared selection means the inspector keeps showing the right message when the user switches between Outline, Flat, and Timeline.
    ///
    @State
    private var selection: LoadedMessage.ID?

    ///
    /// Whether the SwiftUI directory importer is currently presented. Flipped by the toolbar/menu Open Directory… commands.
    ///
    @State
    private var importing: Bool = false

    ///
    /// Time-range selection drawn by the user inside `TimelineView`. When non-`nil`, the lower table in timeline mode is filtered to entries whose date falls within this range (`rangeFilteredEntries`).
    ///
    @State
    private var timelineRange: ClosedRange<Date>?

    ///
    /// Sidebar visibility for the `NavigationSplitView`. Toggled by the toolbar button and the View ▸ Show/Hide Sidebar menu item.
    ///
    @State
    private var columnVisibility: NavigationSplitViewVisibility = .all

    ///
    /// Whether the right-hand inspector pane is shown. Toggled by the toolbar button and the View ▸ Show/Hide Inspector menu item.
    ///
    @State
    private var inspectorPresented: Bool = true

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            FilterSidebar(store: store)
                .navigationSplitViewColumnWidth(min: 400, ideal: 400)
        } detail: {
            detail
                .toolbar { toolbar }
                .navigationTitle(store.directory?.lastPathComponent ?? "Riverview")
                .inspector(isPresented: $inspectorPresented) {
                    MessageInspector(entry: selectedEntry)
                        .inspectorColumnWidth(min: 300, ideal: 300, max: 500)
                }
                .focusedSceneValue(\.viewMode, $mode)
                .focusedSceneValue(\.journalStore, store)
                .focusedSceneValue(\.columnVisibility, $columnVisibility)
                .focusedSceneValue(\.inspectorPresented, $inspectorPresented)
        }
        .onReceive(NotificationCenter.default.publisher(for: .riverviewOpenDirectory)) { _ in
            importing = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .riverviewNextMatch)) { _ in
            advanceMatch(by: 1)
        }
        .onReceive(NotificationCenter.default.publisher(for: .riverviewPreviousMatch)) { _ in
            advanceMatch(by: -1)
        }
        .fileImporter(
            isPresented: $importing,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
                case let .success(urls):
                    if let url = urls.first {
                        openDirectory(url)
                    }
                case let .failure(error):
                    store.setError(error.localizedDescription)
            }
        }
    }

    // MARK: - Detail content

    @ViewBuilder
    private var detail: some View {
        if store.directory == nil {
            ContentUnavailableView {
                Label("No journal open", systemImage: "doc.text.magnifyingglass")
            } description: {
                Text("Open a directory containing Rivers log files to begin.")
            } actions: {
                Button("Open Directory…") { importing = true }
                    .keyboardShortcut("o")
            }
        } else if store.entries.isEmpty {
            ContentUnavailableView("No messages", systemImage: "tray", description: Text("This directory does not contain any decodable Rivers messages yet."))
        } else {
            switch mode {
                case .outline:
                    MessageOutlineView(
                        roots: store.activityRoots,
                        highlightedLevels: store.levelFilter,
                        rules: store.activeFilterRules,
                        matchIDs: store.matchIDs,
                        matchPositions: outlineMatchPositions,
                        totalEntryCount: store.entries.count,
                        selectedMatchPosition: selectedMatchPosition(in: outlineMatchPositions, entries: store.entries),
                        selection: $selection
                    )
                case .flat:
                    MessageTableView(
                        entries: store.entries,
                        highlightedLevels: store.levelFilter,
                        rules: store.activeFilterRules,
                        matchIDs: store.matchIDs,
                        matchPositions: flatMatchPositions,
                        selectedMatchPosition: selectedMatchPosition(in: flatMatchPositions, entries: store.entries),
                        selection: $selection
                    )
                case .timeline:
                    VSplitView {
                        TimelineView(
                            activities: TimelineActivity.aggregate(from: store.entries),
                            highlightedLevels: store.levelFilter,
                            matchIDs: store.matchIDs,
                            selection: $selection,
                            selectedRange: $timelineRange
                        )
                        .frame(minHeight: 200, idealHeight: 320)

                        let lowerEntries = rangeFilteredEntries
                        let lowerPositions = matchPositions(in: lowerEntries)

                        MessageTableView(
                            entries: lowerEntries,
                            highlightedLevels: store.levelFilter,
                            rules: store.activeFilterRules,
                            matchIDs: store.matchIDs,
                            matchPositions: lowerPositions,
                            selectedMatchPosition: selectedMatchPosition(in: lowerPositions, entries: lowerEntries),
                            selection: $selection
                        )
                        .frame(minHeight: 160)
                    }
            }
        }
    }

    ///
    /// `store.entries` filtered to entries whose date falls inside `timelineRange`. Used by the lower table in timeline mode to keep both halves in sync with the user's drag-selected range.
    ///
    private var rangeFilteredEntries: [LoadedMessage] {
        guard let range = timelineRange else {
            return store.entries
        }

        return store.entries.filter { range.contains($0.message.date) }
    }

    ///
    /// Chronological indices (within `store.entries`) of currently matching entries — used by the outline view's trailing tick gutter.
    ///
    private var outlineMatchPositions: [Int] {
        matchPositions(in: store.entries)
    }

    ///
    /// Chronological indices (within `store.entries`) of currently matching entries — used by the flat table.
    ///
    private var flatMatchPositions: [Int] {
        matchPositions(in: store.entries)
    }

    ///
    /// Indices of `entries` whose id is in `store.matchIDs`. The shared helper used by every view's tick gutter.
    ///
    private func matchPositions(in entries: [LoadedMessage]) -> [Int] {
        let matches = store.matchIDs

        guard !matches.isEmpty else {
            return []
        }

        return entries.enumerated().compactMap { index, entry in
            matches.contains(entry.id) ? index : nil
        }
    }

    ///
    /// Position of the currently selected entry within `positions` (which are indices into `entries`), or `nil` if the selection isn't a match. Drives the brighter "you are here" tick.
    ///
    private func selectedMatchPosition(in positions: [Int], entries: [LoadedMessage]) -> Int? {
        guard let selection else {
            return nil
        }
        guard let index = entries.firstIndex(where: { $0.id == selection }) else {
            return nil
        }
        return positions.contains(index) ? index : nil
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Button {
                importing = true
            } label: {
                Label("Open Directory…", systemImage: "folder")
            }
            .help("Open a directory containing Rivers log files")
        }

        ToolbarItem(placement: .navigation) {
            Button {
                store.reload()
            } label: {
                Label("Reload", systemImage: "arrow.clockwise")
            }
            .disabled(store.directory == nil)
            .help("Reload messages from the current directory")
        }

        ToolbarItem {
            Picker("View Mode", selection: $mode) {
                ForEach(ViewMode.allCases) { value in
                    Label(value.label, systemImage: value.systemImage).tag(value)
                }
            }
            .pickerStyle(.segmented)
            .help("Switch between outline, flat, and timeline views")
        }

        ToolbarItem(placement: .primaryAction) {
            Button {
                inspectorPresented.toggle()
            } label: {
                Label("Toggle Inspector", systemImage: "sidebar.right")
            }
            .help("Show or hide the inspector")
        }
    }

    // MARK: - Helpers

    ///
    /// Animate the sidebar between fully visible (`.all`) and hidden (`.detailOnly`).
    ///
    private func toggleSidebar() {
        withAnimation {
            columnVisibility = (columnVisibility == .detailOnly) ? .all : .detailOnly
        }
    }

    ///
    /// Look up the `LoadedMessage` referenced by `selection`. Used to populate the inspector pane.
    ///
    private var selectedEntry: LoadedMessage? {
        guard let selection else {
            return nil
        }
        return store.entries.first { $0.id == selection }
    }

    ///
    /// Hand a directory URL to the store, which kicks off an initial read followed by live tailing.
    ///
    private func openDirectory(_ url: URL) {
        store.open(directory: url)
    }

    ///
    /// Move `selection` forward (`step == 1`) or backward (`step == -1`) through `store.matchingEntries`, wrapping at either end. When the current selection isn't a match, the next-match step picks the first match at-or-after `selection` and the previous-match step picks the first match at-or-before `selection`.
    ///
    private func advanceMatch(by step: Int) {
        let matches = store.matchingEntries

        guard !matches.isEmpty else {
            return
        }

        let target: LoadedMessage

        if let currentIndex = matches.firstIndex(where: { $0.id == selection }) {
            let nextIndex = (currentIndex + step + matches.count) % matches.count
            target = matches[nextIndex]
        } else if step >= 0 {
            target = matches.first { firstMatch in
                guard let selection else {
                    return true
                }
                guard let currentEntryIndex = store.entries.firstIndex(where: { $0.id == selection }) else {
                    return true
                }
                guard let firstMatchIndex = store.entries.firstIndex(where: { $0.id == firstMatch.id }) else {
                    return false
                }
                return firstMatchIndex > currentEntryIndex
            } ?? matches[0]
        } else {
            target = matches.last { lastMatch in
                guard let selection else {
                    return true
                }
                guard let currentEntryIndex = store.entries.firstIndex(where: { $0.id == selection }) else {
                    return true
                }
                guard let lastMatchIndex = store.entries.firstIndex(where: { $0.id == lastMatch.id }) else {
                    return false
                }
                return lastMatchIndex < currentEntryIndex
            } ?? matches[matches.count - 1]
        }

        if mode == .timeline, let range = timelineRange, !range.contains(target.message.date) {
            timelineRange = nil
        }

        selection = target.id
    }
}
