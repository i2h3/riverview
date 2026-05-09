// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import Foundation
import SwiftUI

///
/// Format a `Date` as `HH:mm:ss.SSS`. Used by `MessageRow`, `MessageTableView`, and the timeline ruler so timestamps render consistently across every view in the app.
///
func formatted(_ date: Date) -> String {
    timeFormatter.string(from: date)
}

///
/// Render a `Message.arguments` dictionary as a single-line `key=value key=value …` string in deterministic order. Used wherever a compact preview of arguments is shown next to a message label, e.g. in `MessageRow` and the Arguments column of `MessageTableView`.
///
func argumentsPreview(_ arguments: [String: String?]) -> String {
    arguments
        .sorted { $0.key < $1.key }
        .map { "\($0.key)=\($0.value ?? "nil")" }
        .joined(separator: " ")
}

///
/// Wrap `text` in an `AttributedString` and paint a soft yellow background over every substring that triggered an active `FilterRule` whose `subject` either matches `subject` or is `.any`. Negated operators contribute no inline mark — they match by absence, so there is no specific substring to underline.
///
/// Used by `MessageRow` and `MessageTableView` to draw inline find-in-document style highlights inside message labels and argument previews. The visual style is intentionally close to Xcode's find highlight so the affordance is immediately recognisable.
///
func highlightedText(_ text: String, with rules: [FilterRule], in subject: FilterSubject) -> AttributedString {
    var attributed = AttributedString(text)

    let applicable = rules.filter { rule in
        !rule.isEmpty && rule.op.producesInlineHighlight && (rule.subject == subject || rule.subject == .any)
    }

    guard !applicable.isEmpty else {
        return attributed
    }

    let highlight = Color.yellow.opacity(0.45)

    for rule in applicable {
        let needle = rule.value

        switch rule.op {
            case .contains:
                var cursor = attributed.startIndex

                while cursor < attributed.endIndex {
                    guard let found = attributed[cursor ..< attributed.endIndex].range(of: needle, options: .caseInsensitive) else {
                        break
                    }

                    attributed[found].backgroundColor = highlight
                    cursor = found.upperBound
                }
            case .equals:
                if text.compare(needle, options: .caseInsensitive) == .orderedSame {
                    attributed.backgroundColor = highlight
                }
            case .beginsWith:
                if let found = attributed.range(of: needle, options: [.caseInsensitive, .anchored]) {
                    attributed[found].backgroundColor = highlight
                }
            case .endsWith:
                if let found = attributed.range(of: needle, options: [.caseInsensitive, .anchored, .backwards]) {
                    attributed[found].backgroundColor = highlight
                }
            case .doesNotContain, .doesNotEqual:
                break
        }
    }

    return attributed
}

///
/// Cached formatter shared by `formatted(_:)` to avoid repeatedly allocating a `DateFormatter`, which is expensive on the main thread.
///
private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSS"
    return formatter
}()
