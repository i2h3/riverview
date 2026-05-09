// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import Foundation
import Observation
import Rivers

///
/// Source of truth for the journal currently being viewed. `RiverviewApp` owns one instance and hands it to `ContentView`, which projects it onto the sidebar (`FilterSidebar`), the three view modes (`MessageOutlineView`, `MessageTableView`, `TimelineView`), and the inspector (`MessageInspector`).
///
/// The store is `@Observable` so SwiftUI re-renders dependent views automatically when entries arrive. New messages can come from two directions: an initial bulk read of the directory by `Rivers.FileJournalReader`, and live appends tailed by `JournalWatcher`. Both funnel into `appendIfNew(_:)` which assigns a monotonic id (used by `LoadedMessage`) and inserts into `entries` while keeping it sorted by date.
///
@Observable
@MainActor
final class JournalStore {
    ///
    /// The directory currently being watched, or `nil` if no journal is open. Set by `open(directory:)`; cleared by `close()`.
    ///
    private(set) var directory: URL?

    ///
    /// All messages loaded from the journal so far, kept in chronological order. Indexed by `LoadedMessage.id` for selection.
    ///
    private(set) var entries: [LoadedMessage] = []

    ///
    /// `true` when `JournalWatcher` is actively tailing `log.jsonl`. Surfaced as the green/grey indicator in `FilterSidebar`.
    ///
    private(set) var isWatching: Bool = false

    ///
    /// Most recent error message, e.g. from a failed read. Displayed in `FilterSidebar`.
    ///
    private(set) var lastError: String?

    ///
    /// Levels the user has enabled in `FilterSidebar`. Drives the dimming behaviour in every view mode and the badge filtering in the sidebar.
    ///
    var levelFilter: Set<Level> = [.debug, .info, .error]

    ///
    /// Mail.app-style filter rules edited in `FilterSidebar`. Combined with logical AND by `matchingEntries`. Seeded with one default placeholder rule (`.any` / `.contains` / `""`) so the sidebar always presents a search-ready row; `activeFilterRules` skips empty-value rules, so the placeholder doesn't itself filter anything until the user types into it. The Filters section's "−" button is wired to keep this invariant — removing the only remaining rule replaces it with a fresh placeholder rather than leaving the array empty.
    ///
    var filterRules: [FilterRule] = [FilterRule()]

    private var nextID: Int = 0
    private var watcher: JournalWatcher?
    private var seenKeys: Set<String> = []
    private var securityScopedURL: URL?

    ///
    /// Filter rules that actually have a non-empty value. `JournalStore` skips empty rules so a freshly added rule does not begin highlighting "everything" or "nothing" while the user is typing.
    ///
    var activeFilterRules: [FilterRule] {
        filterRules.filter { !$0.isEmpty }
    }

    ///
    /// Entries that satisfy every active filter rule, in chronological order. Used by `ContentView` to drive Next/Previous match navigation and by `FilterSidebar` for the match counter. When no active rules exist the list is empty — there is nothing to navigate between when nothing is filtered.
    ///
    var matchingEntries: [LoadedMessage] {
        let rules = activeFilterRules

        guard !rules.isEmpty else {
            return []
        }

        return entries.filter { entry in
            rules.allSatisfy { $0.matches(entry) }
        }
    }

    ///
    /// Identifiers of entries in `matchingEntries`, exposed as a `Set` for O(1) "is this row a match?" lookups inside the row views.
    ///
    var matchIDs: Set<LoadedMessage.ID> {
        Set(matchingEntries.map(\.id))
    }

    ///
    /// Entries that pass the level filter *and* every active filter rule. Used by `FilterSidebar` to display the "highlighted / total" status. With no rules and every level enabled, this equals `entries`.
    ///
    var highlightedEntries: [LoadedMessage] {
        let rules = activeFilterRules

        return entries.filter { entry in
            guard levelFilter.contains(entry.message.level) else {
                return false
            }
            return rules.allSatisfy { $0.matches(entry) }
        }
    }

    ///
    /// `entries` arranged into a tree by activity path, ready for `MessageOutlineView` to display via `OutlineGroup`. The tree always reflects the full journal — filter rules highlight rather than reduce, so the surrounding activity context stays visible.
    ///
    var activityRoots: [ActivityNode] {
        ActivityNode.tree(from: entries)
    }

    ///
    /// Open the directory at `url`: stops any existing watcher, claims security-scoped access, performs an initial read of all `*.jsonl` files via `Rivers.FileJournalReader`, then starts a `JournalWatcher` to tail subsequent appends.
    ///
    func open(directory url: URL) {
        stopWatching()
        releaseSecurityScopedAccess()

        if url.startAccessingSecurityScopedResource() {
            securityScopedURL = url
        }

        directory = url
        entries.removeAll()
        seenKeys.removeAll()
        nextID = 0
        lastError = nil

        loadSnapshot()
        startWatching()
    }

    ///
    /// Surface an error message to the UI. Called by `ContentView` when the SwiftUI `.fileImporter` reports a failure.
    ///
    func setError(_ message: String) {
        lastError = message
    }

    ///
    /// Re-read the current directory from scratch. Backs the Reload menu item and toolbar button.
    ///
    func reload() {
        guard directory != nil else {
            return
        }
        stopWatching()
        entries.removeAll()
        seenKeys.removeAll()
        nextID = 0
        loadSnapshot()
        startWatching()
    }

    ///
    /// Stop watching, drop all entries, and forget the directory. Currently unused by the UI but kept for symmetry with `open(directory:)`.
    ///
    func close() {
        stopWatching()
        releaseSecurityScopedAccess()
        directory = nil
        entries.removeAll()
        seenKeys.removeAll()
        nextID = 0
    }

    private func releaseSecurityScopedAccess() {
        if let url = securityScopedURL {
            url.stopAccessingSecurityScopedResource()
            securityScopedURL = nil
        }
    }

    private func loadSnapshot() {
        guard let directory else {
            return
        }

        let configuration = FileJournalConfiguration(directory: directory)
        let reader = FileJournalReader(configuration: configuration)

        do {
            let messages = try reader.read()

            for message in messages {
                appendIfNew(message)
            }
        } catch {
            lastError = "Failed to read journal: \(error.localizedDescription)"
        }
    }

    private func startWatching() {
        guard let directory else {
            return
        }

        let activeURL = directory.appendingPathComponent("log.jsonl")
        let initialOffset: UInt64 = if let attrs = try? FileManager.default.attributesOfItem(atPath: activeURL.path),
                                       let size = attrs[.size] as? UInt64
        {
            size
        } else {
            0
        }

        let watcher = JournalWatcher(
            directory: directory,
            onAppend: { [weak self] message in
                self?.appendIfNew(message)
            },
            onRotate: { [weak self] in
                self?.handleRotation()
            }
        )

        self.watcher = watcher
        watcher.start(initialOffset: initialOffset)
        isWatching = true
    }

    private func stopWatching() {
        watcher?.stop()
        watcher = nil
        isWatching = false
    }

    private func handleRotation() {
        guard let directory else {
            return
        }

        let configuration = FileJournalConfiguration(directory: directory)
        let reader = FileJournalReader(configuration: configuration)

        if let messages = try? reader.read() {
            for message in messages {
                appendIfNew(message)
            }
        }
    }

    private func appendIfNew(_ message: Message) {
        let key = identityKey(for: message)

        if seenKeys.contains(key) {
            return
        }

        seenKeys.insert(key)

        let entry = LoadedMessage(id: nextID, message: message)
        nextID += 1

        if let last = entries.last, last.message.date <= message.date {
            entries.append(entry)
        } else {
            let index = entries.firstIndex { $0.message.date > message.date } ?? entries.endIndex
            entries.insert(entry, at: index)
        }
    }

    private func identityKey(for message: Message) -> String {
        "\(message.activity.description)|\(message.date.timeIntervalSinceReferenceDate)|\(message.label)"
    }
}
