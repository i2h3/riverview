// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import Foundation
import Rivers

///
/// One Rivers `Message` paired with a stable, monotonic identifier minted by `JournalStore.appendIfNew(_:)`. Selection state across the app (sidebar, outline, flat, timeline, inspector) is tracked by `LoadedMessage.ID` so it survives reordering and re-reads of the underlying journal.
///
/// Equality and hashing are based solely on `id`. Two loaded messages with the same id are considered identical regardless of their `message` payload, which is what SwiftUI selection bindings expect.
///
struct LoadedMessage: Identifiable, Hashable, Sendable {
    ///
    /// Stable identifier within a single `JournalStore` lifetime. Reassigned on `JournalStore.reload()` and `JournalStore.open(directory:)`.
    ///
    let id: Int

    ///
    /// The decoded Rivers `Message` payload — activity, parent, date, level, label, and arguments.
    ///
    let message: Message

    static func == (lhs: LoadedMessage, rhs: LoadedMessage) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
