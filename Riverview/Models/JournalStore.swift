// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import Foundation
import Observation
import Rivers

enum ViewMode: String, CaseIterable, Identifiable {
    case outline
    case flat

    var id: String {
        rawValue
    }

    var label: String {
        switch self {
            case .outline: "Outline"
            case .flat: "Flat"
        }
    }

    var systemImage: String {
        switch self {
            case .outline: "list.bullet.indent"
            case .flat: "list.bullet"
        }
    }
}

@Observable
@MainActor
final class JournalStore {
    private(set) var directory: URL?
    private(set) var entries: [LoadedMessage] = []
    private(set) var isWatching: Bool = false
    private(set) var lastError: String?

    var levelFilter: Set<Level> = [.debug, .info, .error]
    var labelQuery: String = ""

    private var nextID: Int = 0
    private var watcher: JournalWatcher?
    private var seenKeys: Set<String> = []
    private var securityScopedURL: URL?

    var filteredEntries: [LoadedMessage] {
        let query = labelQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return entries.filter { entry in
            if query.isEmpty {
                return true
            }

            if entry.message.label.lowercased().contains(query) {
                return true
            }

            return entry.message.arguments.contains { _, value in
                value.lowercased().contains(query)
            }
        }
    }

    var highlightedEntries: [LoadedMessage] {
        filteredEntries.filter { levelFilter.contains($0.message.level) }
    }

    var activityRoots: [ActivityNode] {
        ActivityNode.tree(from: filteredEntries)
    }

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

    func setError(_ message: String) {
        lastError = message
    }

    private func releaseSecurityScopedAccess() {
        if let url = securityScopedURL {
            url.stopAccessingSecurityScopedResource()
            securityScopedURL = nil
        }
    }

    func reload() {
        guard directory != nil else { return }
        stopWatching()
        entries.removeAll()
        seenKeys.removeAll()
        nextID = 0
        loadSnapshot()
        startWatching()
    }

    func close() {
        stopWatching()
        releaseSecurityScopedAccess()
        directory = nil
        entries.removeAll()
        seenKeys.removeAll()
        nextID = 0
    }

    private func loadSnapshot() {
        guard let directory else { return }

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
        guard let directory else { return }

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
        guard let directory else { return }

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
