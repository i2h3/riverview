// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import Rivers
import SwiftUI

///
/// One row in the `MessageOutlineView` outline. An `ActivityNode` either represents an actual message (in which case the row delegates to `MessageRow`) or a synthetic ancestor introduced to give the tree intermediate parents (in which case the row shows the activity path with a placeholder icon).
///
/// Messages whose level is filtered out by the user are dimmed but still drawn, so structural context is preserved. Matched rows (those whose entry id is in `matchIDs`) paint a soft accent-colored row background via `.listRowBackground(...)` and forward the active rules to `MessageRow` so the matched substrings inside the label and arguments are highlighted inline.
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

    ///
    /// Active filter rules forwarded to `MessageRow` for inline substring highlighting.
    ///
    let rules: [FilterRule]

    ///
    /// Identifiers of entries currently matching every active rule. Drives the row-wide accent background applied via `.listRowBackground(...)`.
    ///
    let matchIDs: Set<LoadedMessage.ID>

    var body: some View {
        Group {
            if let entry = node.entry {
                MessageRow(entry: entry, rules: rules)
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
        .listRowBackground(rowBackground)
    }

    ///
    /// Soft accent tint applied to rows whose entry is currently matching the rule set; `nil` (the default List row background) otherwise. Synthetic ancestor nodes have no entry and are never tinted.
    ///
    @ViewBuilder
    private var rowBackground: some View {
        if let entry = node.entry, matchIDs.contains(entry.id) {
            Color.accentColor.opacity(0.12)
        } else {
            Color.clear
        }
    }
}
