// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import SwiftUI

@main
struct RiverviewApp: App {
    @State private var store = JournalStore()

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
        }
    }
}

extension Notification.Name {
    static let riverviewOpenDirectory = Notification.Name("Riverview.OpenDirectory")
}
