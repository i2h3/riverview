// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import SwiftUI

///
/// `FocusedValueKey` exposing the focused window's `NavigationSplitViewVisibility` binding so the View ▸ Show/Hide Sidebar menu item in `RiverviewApp` can toggle the sidebar of whichever window is in focus.
///
struct ColumnVisibilityFocusedValueKey: FocusedValueKey {
    ///
    /// A two-way binding to the focused window's split view visibility.
    ///
    typealias Value = Binding<NavigationSplitViewVisibility>
}
