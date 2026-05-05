// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import Rivers
import SwiftUI
import UniformTypeIdentifiers

///
/// Top-level layout: a three-column `NavigationSplitView` with `FilterSidebar` on the left, the active view mode in the centre, and `MessageInspector` on the right. Owned by `RiverviewApp`'s `WindowGroup`.
///
/// All cross-view state — the journal store, the current selection, the time-range filter, the sidebar/inspector visibility, and the picked view mode — lives here as `@State` and is published through `.focusedSceneValue(...)` so menu commands in `RiverviewApp` can act on the focused window.
///
struct ContentView: View {
    ///
    /// The journal currently being displayed. Owned by `RiverviewApp`; passed in here so this view holds no journal state of its own.
    ///
    @Bindable var store: JournalStore

    ///
    /// Which view mode is currently active. Driven by both the toolbar segmented picker and the View ▸ View Mode menu (which reads this through the focused scene value bridge).
    ///
    @State private var mode: ViewMode = .outline

    ///
    /// The currently selected entry across all view modes and the inspector. Using a single shared selection means the inspector keeps showing the right message when the user switches between Outline, Flat, and Timeline.
    ///
    @State private var selection: LoadedMessage.ID?

    ///
    /// Whether the SwiftUI directory importer is currently presented. Flipped by the toolbar/menu Open Directory… commands.
    ///
    @State private var importing: Bool = false

    ///
    /// Time-range selection drawn by the user inside `TimelineView`. When non-`nil`, the lower table in timeline mode is filtered to entries whose date falls within this range (`rangeFilteredEntries`).
    ///
    @State private var timelineRange: ClosedRange<Date>?

    ///
    /// Sidebar visibility for the `NavigationSplitView`. Toggled by the toolbar button and the View ▸ Show/Hide Sidebar menu item.
    ///
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    ///
    /// Whether the right-hand inspector pane is shown. Toggled by the toolbar button and the View ▸ Show/Hide Inspector menu item.
    ///
    @State private var inspectorPresented: Bool = true

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            FilterSidebar(store: store)
                .navigationSplitViewColumnWidth(min: 220, ideal: 260)
        } detail: {
            detail
                .toolbar { toolbar }
                .navigationTitle(store.directory?.lastPathComponent ?? "Riverview")
                .inspector(isPresented: $inspectorPresented) {
                    MessageInspector(entry: selectedEntry)
                        .inspectorColumnWidth(min: 240, ideal: 320, max: 500)
                }
                .focusedSceneValue(\.viewMode, $mode)
                .focusedSceneValue(\.journalStore, store)
                .focusedSceneValue(\.columnVisibility, $columnVisibility)
                .focusedSceneValue(\.inspectorPresented, $inspectorPresented)
        }
        .onReceive(NotificationCenter.default.publisher(for: .riverviewOpenDirectory)) { _ in
            importing = true
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
                    MessageOutlineView(roots: store.activityRoots, highlightedLevels: store.levelFilter, selection: $selection)
                case .flat:
                    MessageTableView(entries: store.filteredEntries, highlightedLevels: store.levelFilter, selection: $selection)
                case .timeline:
                    VSplitView {
                        TimelineView(
                            activities: TimelineActivity.aggregate(from: store.filteredEntries),
                            highlightedLevels: store.levelFilter,
                            selection: $selection,
                            selectedRange: $timelineRange
                        )
                        .frame(minHeight: 200, idealHeight: 320)

                        MessageTableView(
                            entries: rangeFilteredEntries,
                            highlightedLevels: store.levelFilter,
                            selection: $selection
                        )
                        .frame(minHeight: 160)
                    }
            }
        }
    }

    ///
    /// `store.filteredEntries` further filtered to entries whose date falls inside `timelineRange`. Used by the lower table in timeline mode to keep both halves in sync with the user's drag-selected range.
    ///
    private var rangeFilteredEntries: [LoadedMessage] {
        let entries = store.filteredEntries

        guard let range = timelineRange else {
            return entries
        }

        return entries.filter { range.contains($0.message.date) }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Button {
                toggleSidebar()
            } label: {
                Label("Toggle Sidebar", systemImage: "sidebar.leading")
            }
            .help("Show or hide the sidebar")
        }

        ToolbarItem(placement: .navigation) {
            Button {
                importing = true
            } label: {
                Label("Open Directory…", systemImage: "folder")
            }
            .help("Open a directory containing Rivers log files")
        }

        ToolbarItem {
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
        guard let selection else { return nil }
        return store.entries.first { $0.id == selection }
    }

    ///
    /// Hand a directory URL to the store, which kicks off an initial read followed by live tailing.
    ///
    private func openDirectory(_ url: URL) {
        store.open(directory: url)
    }
}
