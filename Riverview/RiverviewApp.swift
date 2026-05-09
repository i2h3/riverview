// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import SwiftUI

///
/// Root scene of the Riverview app. Owns the singleton `JournalStore` (one journal per window for now) and adds the menu commands that operate on whichever `ContentView` is currently focused.
///
/// All inter-view state — view mode, sidebar visibility, inspector visibility, the active journal — is published by `ContentView` via `.focusedSceneValue(...)` and read here through `@FocusedBinding`/`@FocusedValue`. That is what lets a global menu item act on the focused window without holding its own copy of the state.
///
@main
struct RiverviewApp: App {
    ///
    /// The journal currently displayed in the (single) window. Replaced when the user opens a different directory; observed reactively because `JournalStore` is `@Observable`.
    ///
    @State
    private var store = JournalStore()

    ///
    /// Binding to the focused window's `ViewMode`, supplied by `ContentView`. Drives the View ▸ View Mode menu picker.
    ///
    @FocusedBinding(\.viewMode)
    private var focusedViewMode: ViewMode?

    ///
    /// The `JournalStore` of the focused window, used to enable/disable and trigger commands such as Reload.
    ///
    @FocusedValue(\.journalStore)
    private var focusedStore: JournalStore?

    ///
    /// Binding to the focused window's sidebar visibility. Drives the View ▸ Show/Hide Sidebar menu item.
    ///
    @FocusedBinding(\.columnVisibility)
    private var focusedColumnVisibility: NavigationSplitViewVisibility?

    ///
    /// Binding to whether the focused window's inspector pane is presented. Drives the View ▸ Show/Hide Inspector menu item.
    ///
    @FocusedBinding(\.inspectorPresented)
    private var focusedInspectorPresented: Bool?

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .frame(minWidth: 900, minHeight: 540)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Directory…") {
                    NotificationCenter.default.post(name: .riverviewOpenDirectory, object: nil)
                }
                .keyboardShortcut("o")
            }

            CommandGroup(after: .newItem) {
                Divider()
                Button("Reload") {
                    focusedStore?.reload()
                }
                .keyboardShortcut("r")
                .disabled(focusedStore?.directory == nil)
            }

            CommandGroup(after: .textEditing) {
                Divider()
                Button("Next Match") {
                    NotificationCenter.default.post(name: .riverviewNextMatch, object: nil)
                }
                .keyboardShortcut("g")
                .disabled(focusedStore?.matchingEntries.isEmpty ?? true)

                Button("Previous Match") {
                    NotificationCenter.default.post(name: .riverviewPreviousMatch, object: nil)
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])
                .disabled(focusedStore?.matchingEntries.isEmpty ?? true)
            }

            CommandGroup(before: .toolbar) {
                Picker("View Mode", selection: Binding(
                    get: { focusedViewMode ?? .outline },
                    set: { focusedViewMode = $0 }
                )) {
                    ForEach(ViewMode.allCases) { value in
                        Label(value.label, systemImage: value.systemImage)
                            .tag(value)
                            .keyboardShortcut(value.keyboardShortcut, modifiers: .command)
                    }
                }
                .disabled(focusedViewMode == nil)
                Divider()

                Button(sidebarMenuTitle) {
                    if let current = focusedColumnVisibility {
                        withAnimation {
                            focusedColumnVisibility = (current == .detailOnly) ? .all : .detailOnly
                        }
                    }
                }
                .keyboardShortcut("s", modifiers: [.command, .control])
                .disabled(focusedColumnVisibility == nil)

                Button(inspectorMenuTitle) {
                    focusedInspectorPresented?.toggle()
                }
                .keyboardShortcut("i", modifiers: [.command, .control])
                .disabled(focusedInspectorPresented == nil)
            }
        }
    }

    ///
    /// Menu-item title that flips between "Show Sidebar" and "Hide Sidebar" depending on the focused window's current state, mirroring how Finder and Mail label theirs.
    ///
    private var sidebarMenuTitle: String {
        focusedColumnVisibility == .detailOnly ? "Show Sidebar" : "Hide Sidebar"
    }

    ///
    /// Menu-item title for the inspector toggle, matching `sidebarMenuTitle`'s show/hide convention.
    ///
    private var inspectorMenuTitle: String {
        (focusedInspectorPresented ?? false) ? "Hide Inspector" : "Show Inspector"
    }
}
