// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import Foundation

///
/// `Notification.Name` values used to bridge global commands (defined in `RiverviewApp.body`'s `.commands { … }`) to the active `ContentView`. The app posts a notification; the focused content view observes it and reacts.
///
extension Notification.Name {
    ///
    /// Posted by the File ▸ Open Directory… menu item. `ContentView` listens for it and presents the directory importer that hands a URL to `JournalStore.open(directory:)`.
    ///
    static let riverviewOpenDirectory = Notification.Name("Riverview.OpenDirectory")
}
