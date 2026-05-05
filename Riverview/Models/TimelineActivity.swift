// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import Foundation
import Rivers

///
/// Aggregated representation of one activity used by `TimelineView`. Where `ActivityNode` describes the activity hierarchy for the outline, `TimelineActivity` collapses each activity into a single row with start/end timestamps so it can be drawn as a Gantt-style bar.
///
/// Produced by `aggregate(from:)` in `ContentView`'s timeline branch. The `level` is the highest level among the activity's messages so an error somewhere in the activity colors the whole bar red, and `primaryEntry` is the first message at that level so opening the popover or selecting the bar surfaces the most relevant message.
///
struct TimelineActivity: Identifiable {
    ///
    /// The activity this aggregate represents.
    ///
    let activity: ActivityID

    ///
    /// Display label for the bar. Taken from the activity's *first* message so a meaningful description ("Processing user request") survives even when the dominant level comes from a later, less descriptive message ("Failed.").
    ///
    let label: String

    ///
    /// Highest `Level` among `entries`, ranked by `Level.sortRank`. Drives the bar's color in `TimelineActivityBar`.
    ///
    let level: Level

    ///
    /// Timestamp of the activity's first message — left edge of the bar in `TimelineView`.
    ///
    let start: Date

    ///
    /// Timestamp of the activity's last message — right edge of the bar in `TimelineView`.
    ///
    let end: Date

    ///
    /// All messages that share this `ActivityID`, sorted chronologically with `LoadedMessage.id` as a tiebreaker.
    ///
    let entries: [LoadedMessage]

    ///
    /// Entry shown in the popover and inspector when the user selects the bar. Picked as the first message at the activity's dominant `level` so an "error" bar surfaces the actual error message rather than an earlier info-level breadcrumb.
    ///
    let primaryEntry: LoadedMessage

    var id: String { activity.description }

    ///
    /// Total duration of the activity in seconds. Used by `TimelineView.width(for:pps:)` to size the bar.
    ///
    var duration: TimeInterval { end.timeIntervalSince(start) }

    ///
    /// Group `entries` by activity, choose a primary entry per group, and return one `TimelineActivity` per distinct `ActivityID` sorted by start time. Called by `ContentView` whenever the timeline mode renders.
    ///
    static func aggregate(from entries: [LoadedMessage]) -> [TimelineActivity] {
        let grouped = Dictionary(grouping: entries) { $0.message.activity }

        let activities: [TimelineActivity] = grouped.compactMap { id, msgs in
            let sorted = msgs.sorted { lhs, rhs in
                if lhs.message.date != rhs.message.date {
                    return lhs.message.date < rhs.message.date
                }
                return lhs.id < rhs.id
            }

            guard let first = sorted.first, let last = sorted.last else {
                return nil
            }

            let level = highestLevel(in: sorted)
            let primary = sorted.first { $0.message.level == level } ?? first

            return TimelineActivity(
                activity: id,
                label: first.message.label,
                level: level,
                start: first.message.date,
                end: last.message.date,
                entries: sorted,
                primaryEntry: primary
            )
        }

        return activities.sorted { lhs, rhs in
            if lhs.start != rhs.start {
                return lhs.start < rhs.start
            }

            return lhs.activity.description < rhs.activity.description
        }
    }

    private static func highestLevel(in entries: [LoadedMessage]) -> Level {
        entries.map(\.message.level).max(by: { $0.sortRank < $1.sortRank }) ?? .info
    }
}
