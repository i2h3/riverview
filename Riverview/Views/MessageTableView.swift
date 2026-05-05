// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import Foundation
import Rivers
import SwiftUI

///
/// Tabular presentation of journal messages. Used both as the standalone flat view mode and as the lower half of the timeline mode (where `ContentView` filters its `entries` by the timeline's selected range).
///
/// The table always renders rows in chronological order, regardless of column. User-driven sorting is intentionally disabled here — the journal's natural axis is time, and every other view in the app respects that, so allowing the user to break that invariant in just this one place would be confusing.
///
struct MessageTableView: View {
    ///
    /// Messages to display. Already filtered by the caller (`store.filteredEntries` for the flat mode, or `rangeFilteredEntries` for the timeline mode's lower table).
    ///
    let entries: [LoadedMessage]

    ///
    /// Levels enabled by the user in `FilterSidebar`. Rows at non-highlighted levels are dimmed via `opacity(for:)`.
    ///
    let highlightedLevels: Set<Level>

    ///
    /// The currently selected entry, shared with the inspector and the other view modes.
    ///
    @Binding var selection: LoadedMessage.ID?

    var body: some View {
        Table(chronological, selection: $selection) {
            TableColumn("Time") { entry in
                Text(formatted(entry.message.date))
                    .font(.system(.caption, design: .monospaced))
                    .opacity(opacity(for: entry))
            }
            .width(min: 90, ideal: 110)

            TableColumn("Level") { entry in
                LevelBadge(level: entry.message.level)
                    .opacity(opacity(for: entry))
            }
            .width(min: 60, ideal: 70)

            TableColumn("Activity") { entry in
                Text(entry.message.activity.description)
                    .font(.system(.caption, design: .monospaced))
                    .opacity(opacity(for: entry))
            }
            .width(min: 60, ideal: 90)

            TableColumn("Label") { entry in
                Text(entry.message.label)
                    .opacity(opacity(for: entry))
            }
            .width(min: 120, ideal: 240)

            TableColumn("Arguments") { entry in
                Text(argumentsPreview(entry.message.arguments))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .opacity(opacity(for: entry))
            }
        }
    }

    ///
    /// Opacity applied to a row: full when its level is highlighted, dimmed otherwise.
    ///
    private func opacity(for entry: LoadedMessage) -> Double {
        highlightedLevels.contains(entry.message.level) ? 1 : 0.35
    }

    ///
    /// `entries` sorted ascending by message date, with `LoadedMessage.id` as a stable tiebreaker for messages sharing the same timestamp.
    ///
    private var chronological: [LoadedMessage] {
        entries.sorted { lhs, rhs in
            if lhs.message.date != rhs.message.date {
                return lhs.message.date < rhs.message.date
            }
            return lhs.id < rhs.id
        }
    }
}
