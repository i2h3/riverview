// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import Foundation
import Rivers

struct LoadedMessage: Identifiable, Hashable {
    let id: Int
    let message: Message

    static func == (lhs: LoadedMessage, rhs: LoadedMessage) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
