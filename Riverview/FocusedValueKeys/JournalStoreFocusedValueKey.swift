// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import SwiftUI

///
/// `FocusedValueKey` exposing the focused window's `JournalStore` so commands defined in `RiverviewApp` (such as Reload) can act on the journal currently in focus rather than holding a global reference.
///
struct JournalStoreFocusedValueKey: FocusedValueKey {
    ///
    /// The `JournalStore` driving the currently focused window.
    ///
    typealias Value = JournalStore
}
