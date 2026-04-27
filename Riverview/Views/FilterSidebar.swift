// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import AppKit
import Rivers
import SwiftUI

struct FilterSidebar: View {
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

    private func name(for level: Level) -> String {
        switch level {
            case .debug: "Debug"
            case .info: "Info"
            case .error: "Error"
        }
    }
}
