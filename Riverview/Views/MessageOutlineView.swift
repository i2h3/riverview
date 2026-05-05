// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import Rivers
import SwiftUI

///
/// The outline mode of `ContentView`. Renders the activity hierarchy from `JournalStore.activityRoots` as a SwiftUI `OutlineGroup` so the user can expand and collapse subtrees.
///
/// Each node is rendered by `MessageOutlineNodeRow`, which delegates to `MessageRow` for actual messages and to a synthetic placeholder row for ancestor activities introduced by `ActivityNode.tree(from:)`.
///
struct MessageOutlineView: View {
    ///
    /// Top-level activity nodes to display. Built by `ActivityNode.tree(from:)` over `JournalStore.filteredEntries`.
    ///
    let roots: [ActivityNode]

    ///
    /// Levels the user has enabled in `FilterSidebar`. Rows at non-highlighted levels are dimmed.
    ///
    let highlightedLevels: Set<Level>

    ///
    /// The currently selected entry. Shared with the inspector and other view modes through `ContentView`.
    ///
    @Binding var selection: LoadedMessage.ID?

    var body: some View {
        List(selection: $selection) {
            OutlineGroup(roots, children: \.optionalChildren) { node in
                MessageOutlineNodeRow(node: node, highlightedLevels: highlightedLevels)
            }
        }
    }
}
