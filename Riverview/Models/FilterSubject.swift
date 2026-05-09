// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import Foundation

///
/// The part of a `Rivers.Message` that a `FilterRule` examines. Selected by the leading popup button in `FilterRuleRow`; together with the rule's `FilterOperator` and value it decides whether a message is a match.
///
/// `.any` lets a single rule scan the whole textual surface of a message — its `label`, every argument key, and every non-`nil` argument value — so the user can search broadly without knowing where the substring lives. The other cases narrow the scope to a single field, mirroring the rule subjects offered in Mail.app.
///
enum FilterSubject: String, CaseIterable, Identifiable, Hashable, Codable {
    ///
    /// Match against the message's label, every argument key, and every non-`nil` argument value. Equivalent to a free-text search, but still using the rule's chosen operator.
    ///
    case any

    ///
    /// Match against the message's `label` property only.
    ///
    case label

    ///
    /// Match against any of the message's argument dictionary *keys*. Useful for "has argument X" rules that don't care about the value.
    ///
    case argumentKey

    ///
    /// Match against any of the message's argument dictionary *values* (skipping `nil`). Useful for finding a token like an identifier wherever it appears in the payload.
    ///
    case argumentValue

    var id: String {
        rawValue
    }

    ///
    /// Human-readable title shown in the subject popup of `FilterRuleRow`.
    ///
    var localizedTitle: String {
        switch self {
            case .any: "Any"
            case .label: "Message label"
            case .argumentKey: "Argument key"
            case .argumentValue: "Argument value"
        }
    }
}
