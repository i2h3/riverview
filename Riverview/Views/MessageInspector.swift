// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import Rivers
import SwiftUI

///
/// Right-hand inspector pane of `ContentView`, displayed via SwiftUI's `.inspector` modifier. Shows full details (level, label, activity, parent, date, arguments) for the message corresponding to the current `selection`.
///
/// Reused inside `TimelineActivityBar`'s popover so clicking a bar in the timeline reveals the same inspector layout in-place — passing the activity's `primaryEntry` (which is selected at the activity's dominant level) so the popover and the bar agree on the level.
///
struct MessageInspector: View {
    ///
    /// The message to display, or `nil` when nothing is selected.
    ///
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

    ///
    /// Wrap a labelled section: small caps title above, content below. Used for every field in the inspector to keep the layout consistent.
    ///
    private func fieldGroup(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
            content()
        }
    }
}
