// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import SwiftUI

///
/// Typed accessors for the focused-scene values published by `ContentView` and consumed by the menu commands in `RiverviewApp`. Each property bridges to a private `FocusedValueKey` type defined alongside it (e.g. `ViewModeFocusedValueKey`) so the keys themselves stay encapsulated while the call sites read like ordinary properties on `FocusedValues`.
///
extension FocusedValues {
    ///
    /// Two-way binding to the focused window's current `ViewMode`. Set by `ContentView` and read by the View ▸ View Mode menu picker.
    ///
    var viewMode: Binding<ViewMode>? {
        get { self[ViewModeFocusedValueKey.self] }
        set { self[ViewModeFocusedValueKey.self] = newValue }
    }

    ///
    /// The focused window's `JournalStore`. Used by Reload and other commands that need to act on the journal currently in focus.
    ///
    var journalStore: JournalStore? {
        get { self[JournalStoreFocusedValueKey.self] }
        set { self[JournalStoreFocusedValueKey.self] = newValue }
    }

    ///
    /// Two-way binding to the focused window's sidebar visibility. Set by `ContentView` and read by the View ▸ Show/Hide Sidebar menu item.
    ///
    var columnVisibility: Binding<NavigationSplitViewVisibility>? {
        get { self[ColumnVisibilityFocusedValueKey.self] }
        set { self[ColumnVisibilityFocusedValueKey.self] = newValue }
    }

    ///
    /// Two-way binding to whether the focused window's inspector pane is presented. Set by `ContentView` and read by the View ▸ Show/Hide Inspector menu item.
    ///
    var inspectorPresented: Binding<Bool>? {
        get { self[InspectorPresentedFocusedValueKey.self] }
        set { self[InspectorPresentedFocusedValueKey.self] = newValue }
    }
}
