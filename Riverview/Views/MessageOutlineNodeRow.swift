// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import Rivers
import SwiftUI

///
/// One row in the `MessageOutlineView` outline. An `ActivityNode` either represents an actual message (in which case the row delegates to `MessageRow`) or a synthetic ancestor introduced to give the tree intermediate parents (in which case the row shows the activity path with a placeholder icon).
///
/// Messages whose level is filtered out by the user are dimmed but still drawn, so structural context is preserved.
///
struct MessageOutlineNodeRow: View {
    ///
    /// The tree node this row renders.
    ///
    let node: ActivityNode

    ///
    /// The user's currently enabled levels (`JournalStore.levelFilter`). Rows whose entry is at a non-highlighted level are drawn at lower opacity.
    ///
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
