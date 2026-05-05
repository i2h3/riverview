// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import Foundation

///
/// Format a `Date` as `HH:mm:ss.SSS`. Used by `MessageRow`, `MessageTableView`, and the timeline ruler so timestamps render consistently across every view in the app.
///
func formatted(_ date: Date) -> String {
    timeFormatter.string(from: date)
}

///
/// Render a `Message.arguments` dictionary as a single-line `key=value key=value …` string in deterministic order. Used wherever a compact preview of arguments is shown next to a message label, e.g. in `MessageRow` and the Arguments column of `MessageTableView`.
///
func argumentsPreview(_ arguments: [String: String]) -> String {
    arguments
        .sorted { $0.key < $1.key }
        .map { "\($0.key)=\($0.value)" }
        .joined(separator: " ")
}

///
/// Cached formatter shared by `formatted(_:)` to avoid repeatedly allocating a `DateFormatter`, which is expensive on the main thread.
///
private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSS"
    return formatter
}()
