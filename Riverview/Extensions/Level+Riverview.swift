// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import Rivers

///
/// Convenience helpers on the Rivers `Level` enum. Kept separate from `LevelBadge` because `sortRank` is general-purpose ordering metadata that should be reachable from any Level-aware code (`TimelineActivity.aggregate(from:)` uses it to find an activity's dominant level).
///
extension Level {
    ///
    /// A monotonic ranking from least to most severe (`debug` < `info` < `error`). Used wherever levels need to be compared, e.g. when picking the "highest" level among an activity's messages.
    ///
    var sortRank: Int {
        switch self {
            case .debug: 0
            case .info: 1
            case .error: 2
        }
    }
}
