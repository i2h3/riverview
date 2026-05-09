// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import Rivers
import SwiftUI

///
/// A single line summarising one `LoadedMessage`. Used inside `MessageOutlineView`'s outline rows (via `MessageOutlineNodeRow`) to render the leaves of the activity tree.
///
/// The layout mirrors the columns of `MessageTableView` (time, level, label, arguments, activity) so the outline and flat views feel like two presentations of the same data. `highlightedText(_:with:in:)` paints the substrings that triggered the active filter rules so the user can see exactly what matched; the row-wide background tint that pairs with this is applied by `MessageOutlineNodeRow` so it lands at List-row level.
///
struct MessageRow: View {
    ///
    /// The message this row represents.
    ///
    let entry: LoadedMessage

    ///
    /// Active filter rules whose substrings should be highlighted inline. Forwarded to `highlightedText(_:with:in:)` for the label and arguments cells.
    ///
    let rules: [FilterRule]

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(formatted(entry.message.date))
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 96, alignment: .leading)

            LevelBadge(level: entry.message.level)
                .frame(width: 56, alignment: .leading)

            Text(highlightedText(entry.message.label, with: rules, in: .label))
                .lineLimit(1)

            if !entry.message.arguments.isEmpty {
                Text(highlightedText(argumentsPreview(entry.message.arguments), with: rules, in: .argumentValue))
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
