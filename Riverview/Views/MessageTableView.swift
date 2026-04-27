// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import Rivers
import SwiftUI

struct MessageTableView: View {
    let entries: [LoadedMessage]
    let highlightedLevels: Set<Level>
    @Binding var selection: LoadedMessage.ID?
    @State private var sortOrder: [KeyPathComparator<LoadedMessage>] = [
        KeyPathComparator(\LoadedMessage.message.date),
    ]

    var body: some View {
        Table(sorted, selection: $selection, sortOrder: $sortOrder) {
            TableColumn("Time", value: \.message.date) { entry in
                Text(formatted(entry.message.date))
                    .font(.system(.caption, design: .monospaced))
                    .opacity(opacity(for: entry))
            }
            .width(min: 90, ideal: 110)

            TableColumn("Level") { entry in
                LevelBadge(level: entry.message.level)
                    .opacity(opacity(for: entry))
            }
            .width(min: 60, ideal: 70)

            TableColumn("Activity") { entry in
                Text(entry.message.activity.description)
                    .font(.system(.caption, design: .monospaced))
                    .opacity(opacity(for: entry))
            }
            .width(min: 60, ideal: 90)

            TableColumn("Label", value: \.message.label) { entry in
                Text(entry.message.label)
                    .opacity(opacity(for: entry))
            }
            .width(min: 120, ideal: 240)

            TableColumn("Arguments") { entry in
                Text(argumentsPreview(entry.message.arguments))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .opacity(opacity(for: entry))
            }
        }
    }

    private func opacity(for entry: LoadedMessage) -> Double {
        highlightedLevels.contains(entry.message.level) ? 1 : 0.35
    }

    private var sorted: [LoadedMessage] {
        entries.sorted(using: sortOrder)
    }
}
