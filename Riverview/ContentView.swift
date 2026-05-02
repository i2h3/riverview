// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import Rivers
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Bindable var store: JournalStore
    @State private var mode: ViewMode = .outline
    @State private var selection: LoadedMessage.ID?
    @State private var importing: Bool = false

    var body: some View {
        NavigationSplitView {
            FilterSidebar(store: store)
                .navigationSplitViewColumnWidth(min: 220, ideal: 260)
        } detail: {
            detail
                .toolbar { toolbar }
                .navigationTitle(store.directory?.lastPathComponent ?? "Riverview")
                .inspector(isPresented: .constant(true)) {
                    MessageInspector(entry: selectedEntry)
                        .inspectorColumnWidth(min: 240, ideal: 320, max: 500)
                }
                .focusedSceneValue(\.viewMode, $mode)
                .focusedSceneValue(\.journalStore, store)
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
            }
        }
    }

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
            .help("Switch between outline and flat views")
        }
    }

    private var selectedEntry: LoadedMessage? {
        guard let selection else { return nil }
        return store.entries.first { $0.id == selection }
    }

    private func openDirectory(_ url: URL) {
        store.open(directory: url)
    }
}
