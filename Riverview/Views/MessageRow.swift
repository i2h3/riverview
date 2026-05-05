// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import Rivers
import SwiftUI

///
/// A single line summarising one `LoadedMessage`. Used inside `MessageOutlineView`'s outline rows (via `MessageOutlineNodeRow`) to render the leaves of the activity tree.
///
/// The layout mirrors the columns of `MessageTableView` (time, level, label, arguments, activity) so the outline and flat views feel like two presentations of the same data.
///
struct MessageRow: View {
    ///
    /// The message this row represents.
    ///
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
