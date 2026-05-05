// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import Foundation
import Rivers

///
/// One node in the activity tree displayed by `MessageOutlineView`. Built from a flat `[LoadedMessage]` by `tree(from:)` so SwiftUI's `OutlineGroup` can render the hierarchy directly.
///
/// A node may stand for either an actual message (`entry` is non-`nil`) or a synthetic ancestor introduced because some descendant was logged but the activity itself produced no message (`entry` is `nil`). `MessageOutlineNodeRow` distinguishes the two visually.
///
struct ActivityNode: Identifiable {
    ///
    /// The activity this node corresponds to.
    ///
    let activity: ActivityID

    ///
    /// The message recorded for this activity, or `nil` if it is a synthetic ancestor introduced solely so its descendants have a parent.
    ///
    var entry: LoadedMessage?

    ///
    /// Child nodes, sorted chronologically.
    ///
    var children: [ActivityNode]

    ///
    /// Stable identifier for SwiftUI selection. Real entries reuse `LoadedMessage.id`; synthetic nodes derive a deterministic negative id from the activity path so it never collides with entry ids.
    ///
    var id: Int {
        if let entry {
            return entry.id
        }

        var hasher = Hasher()
        hasher.combine(activity.path)
        let raw = hasher.finalize()
        return raw >= 0 ? -raw - 1 : raw
    }

    ///
    /// `nil` when there are no children, otherwise `children`. `OutlineGroup` requires a `nil`-able children key path to render leaves without a disclosure indicator.
    ///
    var optionalChildren: [ActivityNode]? {
        children.isEmpty ? nil : children
    }

    ///
    /// Build the forest of activities implied by `entries`. Activities are grouped by their `ActivityID.path`; ancestor paths missing from the data are filled in with synthetic empty-`entry` nodes so the tree is always well-formed. Each level is sorted chronologically (earliest message first).
    ///
    static func tree(from entries: [LoadedMessage]) -> [ActivityNode] {
        var entriesByPath: [[UInt32]: [LoadedMessage]] = [:]
        var allPaths: Set<[UInt32]> = []

        for entry in entries {
            let path = entry.message.activity.path
            entriesByPath[path, default: []].append(entry)

            var ancestor = path

            while !ancestor.isEmpty {
                allPaths.insert(ancestor)
                ancestor.removeLast()
            }
        }

        for key in entriesByPath.keys {
            entriesByPath[key]?.sort { $0.id < $1.id }
        }

        var childrenByParent: [[UInt32]: [[UInt32]]] = [:]

        for path in allPaths {
            let parent = Array(path.dropLast())
            childrenByParent[parent, default: []].append(path)
        }

        func compare(_ lhs: [UInt32], _ rhs: [UInt32]) -> Bool {
            let lhsEntry = entriesByPath[lhs]?.first
            let rhsEntry = entriesByPath[rhs]?.first

            let lhsDate = lhsEntry?.message.date ?? .distantFuture
            let rhsDate = rhsEntry?.message.date ?? .distantFuture

            if lhsDate != rhsDate {
                return lhsDate < rhsDate
            }

            let lhsID = lhsEntry?.id ?? .max
            let rhsID = rhsEntry?.id ?? .max

            if lhsID != rhsID {
                return lhsID < rhsID
            }

            return lhs.lexicographicallyPrecedes(rhs)
        }

        func make(_ path: [UInt32]) -> ActivityNode {
            let activity = ActivityID(path: path)
            let pathEntries = entriesByPath[path] ?? []
            let descendantPaths = (childrenByParent[path] ?? []).sorted(by: compare)
            let descendantNodes = descendantPaths.map { make($0) }

            if pathEntries.count <= 1 {
                return ActivityNode(activity: activity, entry: pathEntries.first, children: descendantNodes)
            }

            let primary = pathEntries.first!
            let extraLeaves = pathEntries.dropFirst().map { entry in
                ActivityNode(activity: activity, entry: entry, children: [])
            }

            return ActivityNode(activity: activity, entry: primary, children: extraLeaves + descendantNodes)
        }

        let rootPaths = (childrenByParent[[]] ?? []).sorted(by: compare)
        return rootPaths.map { make($0) }
    }
}
