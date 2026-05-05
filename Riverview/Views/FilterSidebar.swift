// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import AppKit
import Rivers
import SwiftUI

///
/// Left-hand sidebar of `ContentView`. Surfaces three pieces of user-facing state held by `JournalStore`: the free-text label/argument query (`labelQuery`), the level filter (`levelFilter`), and a status panel showing match counts, the watcher state, and the open directory.
///
/// All controls are bindings into the same `JournalStore` instance — there is no separate sidebar state, so changes immediately reflect in every view mode and the inspector.
///
struct FilterSidebar: View {
    ///
    /// The journal store driving the current window. Bound so the search field and level toggles write straight back to the store.
    ///
    @Bindable var store: JournalStore

    var body: some View {
        Form {
            Section("Search") {
                TextField("Label or argument…", text: $store.labelQuery)
                    .textFieldStyle(.roundedBorder)
            }

            Section("Levels") {
                ForEach([Level.debug, .info, .error], id: \.self) { level in
                    Toggle(isOn: binding(for: level)) {
                        HStack {
                            LevelBadge(level: level)
                            Text(name(for: level))
                        }
                    }
                }
            }

            Section("Status") {
                LabeledContent("Messages", value: "\(store.highlightedEntries.count) / \(store.entries.count)")

                HStack(spacing: 6) {
                    Circle()
                        .fill(store.isWatching ? .green : .secondary)
                        .frame(width: 8, height: 8)
                    Text(store.isWatching ? "Watching" : "Idle")
                        .foregroundStyle(.secondary)
                }

                if let directory = store.directory {
                    LabeledContent("Folder") {
                        Button {
                            NSWorkspace.shared.activateFileViewerSelecting([directory])
                        } label: {
                            Text(directory.lastPathComponent)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .foregroundStyle(.tint)
                        }
                        .buttonStyle(.plain)
                        .help(directory.path)
                    }
                }

                if let error = store.lastError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
    }

    ///
    /// Build a `Bool` binding into a single membership of `store.levelFilter` so each row's `Toggle` reads and mutates the right element of the set.
    ///
    private func binding(for level: Level) -> Binding<Bool> {
        Binding(
            get: { store.levelFilter.contains(level) },
            set: { include in
                if include {
                    store.levelFilter.insert(level)
                } else {
                    store.levelFilter.remove(level)
                }
            }
        )
    }

    ///
    /// Display name for a level next to its `LevelBadge` in the toggle row.
    ///
    private func name(for level: Level) -> String {
        switch level {
            case .debug: "Debug"
            case .info: "Info"
            case .error: "Error"
        }
    }
}
