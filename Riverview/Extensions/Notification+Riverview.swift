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

    ///
    /// Posted by the Edit ▸ Find ▸ Next Match menu item and the Next button in `FilterSidebar`. `ContentView` advances `selection` to the next entry in `JournalStore.matchingEntries`.
    ///
    static let riverviewNextMatch = Notification.Name("Riverview.NextMatch")

    ///
    /// Posted by the Edit ▸ Find ▸ Previous Match menu item and the Previous button in `FilterSidebar`. `ContentView` rewinds `selection` to the previous entry in `JournalStore.matchingEntries`.
    ///
    static let riverviewPreviousMatch = Notification.Name("Riverview.PreviousMatch")
}
