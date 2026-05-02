// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import SwiftUI

@main
struct RiverviewApp: App {
    @State private var store = JournalStore()
    @FocusedBinding(\.viewMode) private var focusedViewMode: ViewMode?
    @FocusedValue(\.journalStore) private var focusedStore: JournalStore?

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

            CommandGroup(before: .toolbar) {
                Picker("View Mode", selection: Binding(
                    get: { focusedViewMode ?? .outline },
                    set: { focusedViewMode = $0 }
                )) {
                    ForEach(ViewMode.allCases) { value in
                        Label(value.label, systemImage: value.systemImage).tag(value)
                    }
                }
                .disabled(focusedViewMode == nil)
                Divider()
            }
        }
    }
}

extension Notification.Name {
    static let riverviewOpenDirectory = Notification.Name("Riverview.OpenDirectory")
}

private struct ViewModeFocusedValueKey: FocusedValueKey {
    typealias Value = Binding<ViewMode>
}

private struct JournalStoreFocusedValueKey: FocusedValueKey {
    typealias Value = JournalStore
}

extension FocusedValues {
    var viewMode: Binding<ViewMode>? {
        get { self[ViewModeFocusedValueKey.self] }
        set { self[ViewModeFocusedValueKey.self] = newValue }
    }

    var journalStore: JournalStore? {
        get { self[JournalStoreFocusedValueKey.self] }
        set { self[JournalStoreFocusedValueKey.self] = newValue }
    }
}
