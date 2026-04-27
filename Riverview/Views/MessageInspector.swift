// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import Rivers
import SwiftUI

struct MessageInspector: View {
    let entry: LoadedMessage?

    var body: some View {
        if let entry {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        LevelBadge(level: entry.message.level)
                        Spacer()
                    }

                    fieldGroup(title: "Label") {
                        Text(entry.message.label)
                            .textSelection(.enabled)
                    }

                    fieldGroup(title: "Activity") {
                        Text(entry.message.activity.description)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    }

                    if let parent = entry.message.parent {
                        fieldGroup(title: "Parent") {
                            Text(parent.description)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }

                    fieldGroup(title: "Date") {
                        Text(entry.message.date.formatted(date: .abbreviated, time: .standard))
                            .textSelection(.enabled)
                    }

                    if !entry.message.arguments.isEmpty {
                        fieldGroup(title: "Arguments") {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(entry.message.arguments.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                    HStack(alignment: .firstTextBaseline) {
                                        Text(key)
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundStyle(.secondary)
                                        Text(value)
                                            .font(.system(.caption, design: .monospaced))
                                            .textSelection(.enabled)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            ContentUnavailableView("No selection", systemImage: "rectangle.dashed", description: Text("Select a message to inspect."))
        }
    }

    private func fieldGroup(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
            content()
        }
    }
}
