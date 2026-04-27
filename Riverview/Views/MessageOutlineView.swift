// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import Rivers
import SwiftUI

struct MessageOutlineView: View {
    let roots: [ActivityNode]
    let highlightedLevels: Set<Level>
    @Binding var selection: LoadedMessage.ID?

    var body: some View {
        List(selection: $selection) {
            OutlineGroup(roots, children: \.optionalChildren) { node in
                NodeRow(node: node, highlightedLevels: highlightedLevels)
            }
        }
    }
}

private struct NodeRow: View {
    let node: ActivityNode
    let highlightedLevels: Set<Level>

    var body: some View {
        if let entry = node.entry {
            MessageRow(entry: entry)
                .opacity(highlightedLevels.contains(entry.message.level) ? 1 : 0.2)
        } else {
            HStack(spacing: 8) {
                Image(systemName: "circle.dotted")
                    .foregroundStyle(.secondary)
                Text(node.activity.description)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
    }
}

struct MessageRow: View {
    let entry: LoadedMessage

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(formatted(entry.message.date))
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 96, alignment: .leading)

            LevelBadge(level: entry.message.level)
                .frame(width: 56, alignment: .leading)

            Text(entry.message.label)
                .lineLimit(1)

            if !entry.message.arguments.isEmpty {
                Text(argumentsPreview(entry.message.arguments))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Text(entry.message.activity.description)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
    }
}

private let timeFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "HH:mm:ss.SSS"
    return f
}()

func formatted(_ date: Date) -> String {
    timeFormatter.string(from: date)
}

func argumentsPreview(_ arguments: [String: String]) -> String {
    arguments
        .sorted { $0.key < $1.key }
        .map { "\($0.key)=\($0.value)" }
        .joined(separator: " ")
}
