// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import Foundation
import Rivers

struct ActivityNode: Identifiable {
    let activity: ActivityID
    var entry: LoadedMessage?
    var children: [ActivityNode]

    var id: Int {
        if let entry {
            return entry.id
        }

        var hasher = Hasher()
        hasher.combine(activity.path)
        let raw = hasher.finalize()
        return raw >= 0 ? -raw - 1 : raw
    }

    var optionalChildren: [ActivityNode]? {
        children.isEmpty ? nil : children
    }

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
