// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import Rivers
import SwiftUI

///
/// The outline mode of `ContentView`. Renders the activity hierarchy from `JournalStore.activityRoots` as a SwiftUI `OutlineGroup` so the user can expand and collapse subtrees.
///
/// Each node is rendered by `MessageOutlineNodeRow`, which delegates to `MessageRow` for actual messages and to a synthetic placeholder row for ancestor activities introduced by `ActivityNode.tree(from:)`. A trailing `MatchScrollIndicator` overlay shows tick marks for every matching entry, mirroring Xcode's editor gutter so the user can see at a glance where matches cluster within long logs.
///
struct MessageOutlineView: View {
    ///
    /// Top-level activity nodes to display. Built by `ActivityNode.tree(from:)` over `JournalStore.entries` (the unfiltered set; rules highlight rather than reduce).
    ///
    let roots: [ActivityNode]

    ///
    /// Levels the user has enabled in `FilterSidebar`. Rows at non-highlighted levels are dimmed.
    ///
    let highlightedLevels: Set<Level>

    ///
    /// Active filter rules forwarded into rows for inline substring highlighting.
    ///
    let rules: [FilterRule]

    ///
    /// Identifiers of entries currently matching every active rule. Forwarded into rows for the row-wide background tint.
    ///
    let matchIDs: Set<LoadedMessage.ID>

    ///
    /// Match positions used by the trailing `MatchScrollIndicator`. Each value is the chronological index of a matching entry within `totalEntryCount` so the tick lands at the proportional vertical position.
    ///
    let matchPositions: [Int]

    ///
    /// Total entry count used as the denominator when projecting `matchPositions` onto the gutter's height.
    ///
    let totalEntryCount: Int

    ///
    /// Position of the currently selected entry inside `matchPositions`, or `nil` when the user's selection isn't on a match. Drives the brighter "you are here" tick.
    ///
    let selectedMatchPosition: Int?

    ///
    /// The currently selected entry. Shared with the inspector and other view modes through `ContentView`.
    ///
    @Binding
    var selection: LoadedMessage.ID?

    var body: some View {
        ScrollViewReader { proxy in
            List(selection: $selection) {
                OutlineGroup(roots, children: \.optionalChildren) { node in
                    MessageOutlineNodeRow(
                        node: node,
                        highlightedLevels: highlightedLevels,
                        rules: rules,
                        matchIDs: matchIDs
                    )
                    .id(node.id)
                }
            }
            .overlay(alignment: .trailing) {
                MatchScrollIndicator(
                    totalCount: totalEntryCount,
                    matchPositions: matchPositions,
                    selectedPosition: selectedMatchPosition
                )
                .padding(.trailing, 2)
            }
            .onChange(of: selection) { _, new in
                if let new {
                    withAnimation { proxy.scrollTo(new, anchor: .center) }
                }
            }
        }
    }
}
