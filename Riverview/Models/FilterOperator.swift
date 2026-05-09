// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import Foundation

///
/// How a `FilterRule` compares its value against the candidate strings produced by its `FilterSubject`. Selected by the second popup button in `FilterRuleRow`.
///
/// Comparisons are always case-insensitive, matching Mail.app's rule editor and the previous free-text search field. For positive operators (`contains`, `equals`, `beginsWith`, `endsWith`) a candidate string contributes a literal needle that `MessageFormatting.highlight(_:matching:in:)` paints inline; negated operators (`doesNotContain`, `doesNotEqual`) contribute no inline highlight because there is no specific substring to underline when a rule matches by absence.
///
enum FilterOperator: String, CaseIterable, Identifiable, Hashable, Codable {
    ///
    /// The candidate string contains the rule's value as a substring. The match anchors the inline yellow background drawn in `MessageRow` and the table cells.
    ///
    case contains

    ///
    /// No candidate string contains the rule's value. Matches by absence, so no inline substring is highlighted.
    ///
    case doesNotContain

    ///
    /// The candidate string equals the rule's value (case-insensitively).
    ///
    case equals

    ///
    /// No candidate string equals the rule's value. Matches by absence.
    ///
    case doesNotEqual

    ///
    /// The candidate string starts with the rule's value.
    ///
    case beginsWith

    ///
    /// The candidate string ends with the rule's value.
    ///
    case endsWith

    var id: String {
        rawValue
    }

    ///
    /// Human-readable title shown in the operator popup of `FilterRuleRow`.
    ///
    var localizedTitle: String {
        switch self {
            case .contains: "Contains"
            case .doesNotContain: "Does not contain"
            case .equals: "Equals"
            case .doesNotEqual: "Does not equal"
            case .beginsWith: "Begins with"
            case .endsWith: "Ends with"
        }
    }

    ///
    /// `true` for operators that match by absence (`doesNotContain`, `doesNotEqual`). Used by `FilterRule.matches(_:)` to flip the quantifier from "any candidate matches" to "no candidate matches".
    ///
    var isNegated: Bool {
        self == .doesNotContain || self == .doesNotEqual
    }

    ///
    /// `true` when the operator's match implies a specific contiguous substring within the candidate string and `MessageFormatting.highlight(_:matching:in:)` should paint that substring. False for negated operators, which match by absence.
    ///
    var producesInlineHighlight: Bool {
        !isNegated
    }
}
