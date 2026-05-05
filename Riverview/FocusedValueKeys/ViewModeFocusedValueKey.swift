// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import SwiftUI

///
/// `FocusedValueKey` exposing the focused window's view-mode binding to scene-wide commands. `ContentView` publishes its `@State mode` via `.focusedSceneValue(\.viewMode, $mode)`, and `RiverviewApp` reads it through `@FocusedBinding(\.viewMode)` to drive the View ▸ View Mode menu picker.
///
struct ViewModeFocusedValueKey: FocusedValueKey {
    ///
    /// A two-way binding to the currently focused window's `ViewMode`.
    ///
    typealias Value = Binding<ViewMode>
}
