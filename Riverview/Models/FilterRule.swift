// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import Foundation
import Rivers

///
/// One Mail.app-style filter rule. The user adds and configures rules in `FilterSidebar` via `FilterRuleRow`; `JournalStore` keeps the array and computes `matchingEntries` / `matchIDs` by ANDing every non-empty rule's `matches(_:)`.
///
/// Empty-value rules are treated as no-ops by `JournalStore`, so a freshly added rule does not immediately mark the entire log as either matched or unmatched while the user is typing. All comparisons are case-insensitive, matching the previous free-text search.
///
struct FilterRule: Identifiable, Hashable, Codable {
    ///
    /// Stable identity for the row in `FilterSidebar` (so SwiftUI keeps the right `TextField` focused while rules are added or removed) and for serialisation if rules are persisted later.
    ///
    let id: UUID

    ///
    /// Which part of the message this rule examines. Drives which strings end up in the candidate set inside `matches(_:)`.
    ///
    var subject: FilterSubject

    ///
    /// How the rule's `value` is compared against each candidate string from the subject.
    ///
    var op: FilterOperator

    ///
    /// The literal string the user typed into the rule's text field. Empty value means the rule is a no-op (skipped by `JournalStore`).
    ///
    var value: String

    init(id: UUID = UUID(), subject: FilterSubject = .any, op: FilterOperator = .contains, value: String = "") {
        self.id = id
        self.subject = subject
        self.op = op
        self.value = value
    }

    ///
    /// `true` when the rule should be skipped because the user has not entered a value yet. `JournalStore.matchingEntries` filters these out before evaluating.
    ///
    var isEmpty: Bool {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    ///
    /// `true` when the rule is in its untouched placeholder state — `.any` subject, `.contains` operator, empty value. `FilterSidebar` uses this to decide whether the "−" button on a single remaining rule has anything useful to do (it doesn't if the rule is already a placeholder).
    ///
    var isDefault: Bool {
        subject == .any && op == .contains && isEmpty
    }

    ///
    /// Evaluate the rule against `entry`. Builds the candidate string set from the message according to `subject`, then quantifies over the candidates with `op`: positive operators return `true` if any candidate satisfies the comparison; negated operators return `true` only if no candidate does (vacuous truth on an empty candidate set).
    ///
    func matches(_ entry: LoadedMessage) -> Bool {
        if isEmpty {
            return true
        }

        let needle = value
        let candidates = candidateStrings(for: entry.message)

        switch op {
            case .contains:
                return candidates.contains { $0.range(of: needle, options: .caseInsensitive) != nil }
            case .doesNotContain:
                return !candidates.contains { $0.range(of: needle, options: .caseInsensitive) != nil }
            case .equals:
                return candidates.contains { $0.compare(needle, options: .caseInsensitive) == .orderedSame }
            case .doesNotEqual:
                return !candidates.contains { $0.compare(needle, options: .caseInsensitive) == .orderedSame }
            case .beginsWith:
                return candidates.contains { $0.range(of: needle, options: [.caseInsensitive, .anchored]) != nil }
            case .endsWith:
                return candidates.contains { $0.range(of: needle, options: [.caseInsensitive, .anchored, .backwards]) != nil }
        }
    }

    ///
    /// Strings on `message` that this rule's `subject` should compare against. Returned as a flat array because every operator works the same way regardless of which field a candidate came from.
    ///
    private func candidateStrings(for message: Message) -> [String] {
        switch subject {
            case .any:
                var candidates: [String] = [message.label]
                candidates.append(contentsOf: message.arguments.keys)
                candidates.append(contentsOf: message.arguments.values.compactMap(\.self))
                return candidates
            case .label:
                return [message.label]
            case .argumentKey:
                return Array(message.arguments.keys)
            case .argumentValue:
                return message.arguments.values.compactMap(\.self)
        }
    }
}
