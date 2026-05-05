// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import SwiftUI

///
/// `FocusedValueKey` exposing the focused window's inspector-presented binding so the View ▸ Show/Hide Inspector menu item in `RiverviewApp` can toggle the right-side inspector pane of whichever window is in focus.
///
struct InspectorPresentedFocusedValueKey: FocusedValueKey {
    ///
    /// A two-way binding to whether the focused window's inspector pane is shown.
    ///
    typealias Value = Binding<Bool>
}
