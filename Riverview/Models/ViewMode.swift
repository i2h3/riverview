// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import SwiftUI

///
/// The three presentation modes for journal entries that `ContentView` switches between via the toolbar picker and the View ▸ View Mode menu in `RiverviewApp`.
///
/// Each case carries the metadata needed to populate menu items and toolbar buttons (`label`, `systemImage`, `keyboardShortcut`) so the picker stays in sync without duplicate definitions.
///
enum ViewMode: String, CaseIterable, Identifiable {
    ///
    /// Hierarchical view backed by `MessageOutlineView`. Activities are rendered as a tree using `ActivityNode`.
    ///
    case outline

    ///
    /// Flat tabular view backed by `MessageTableView`. Lists every message in chronological order.
    ///
    case flat

    ///
    /// Gantt-style view backed by `TimelineView` plus a chronological `MessageTableView` underneath.
    ///
    case timeline

    var id: String {
        rawValue
    }

    ///
    /// `Cmd+1`/`Cmd+2`/`Cmd+3` keyboard shortcut bound to this mode in the View menu.
    ///
    var keyboardShortcut: KeyEquivalent {
        switch self {
            case .outline: "1"
            case .flat: "2"
            case .timeline: "3"
        }
    }

    ///
    /// Human-readable name shown in the toolbar segmented picker and the View menu.
    ///
    var label: String {
        switch self {
            case .outline: "Outline"
            case .flat: "Flat"
            case .timeline: "Timeline"
        }
    }

    ///
    /// SF Symbol used for the toolbar segmented picker and the View menu entries.
    ///
    var systemImage: String {
        switch self {
            case .outline: "list.bullet.indent"
            case .flat: "list.bullet"
            case .timeline: "timeline.selection"
        }
    }
}
