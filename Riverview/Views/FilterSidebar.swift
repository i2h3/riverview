// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import AppKit
import Rivers
import SwiftUI

///
/// Left-hand sidebar of `ContentView`. Surfaces three pieces of user-facing state held by `JournalStore`: the Mail.app-style filter rules (`filterRules`), the level filter (`levelFilter`), and a status panel showing match counts, the watcher state, and the open directory.
///
/// All controls are bindings into the same `JournalStore` instance — there is no separate sidebar state, so changes immediately reflect in every view mode and the inspector. The Filters section always shows at least one rule row (the placeholder seeded by `JournalStore.filterRules`) so the sidebar feels like a full-text-search field that's always ready; `activeFilterRules` ignores the placeholder until the user types into it. Adding more rules happens through the section header's "+" button, which always appends at the bottom; removing the only remaining rule replenishes a fresh placeholder so the search-ready state is reachable in one click. The Previous/Next match buttons post the same notifications wired up by the Edit ▸ Find menu commands in `RiverviewApp`, so clicking the buttons or pressing ⌘G/⇧⌘G triggers the same code path inside `ContentView`.
///
struct FilterSidebar: View {
    ///
    /// The journal store driving the current window. Bound so the rule editor and level toggles write straight back to the store.
    ///
    @Bindable
    var store: JournalStore

    var body: some View {
        Form {
            Section {
                ForEach($store.filterRules) { $rule in
                    FilterRuleRow(
                        rule: $rule,
                        canRemove: store.filterRules.count > 1 || !rule.isDefault,
                        onRemove: { removeRule(rule.id) }
                    )
                }

                if store.matchingEntries.isEmpty == false {
                    HStack {
                        Text(matchSummary)

                        Spacer()

                        Button(action: previousMatch) {
                            Label("Previous Match", systemImage: "chevron.left")
                        }
                        .buttonStyle(.borderless)
                        .labelStyle(.iconOnly)
                        .disabled(store.matchingEntries.isEmpty)
                        .help("Previous match (⇧⌘G)")

                        Button(action: nextMatch) {
                            Label("Next Match", systemImage: "chevron.right")
                        }
                        .buttonStyle(.borderless)
                        .labelStyle(.iconOnly)
                        .disabled(store.matchingEntries.isEmpty)
                        .help("Next match (⌘G)")
                    }
                }
            } header: {
                HStack {
                    Text("Filters")

                    Button(action: appendRule) {
                        Label("Add Filter", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.secondary)
                    .help("Add another rule")

                    Spacer()
                }
            }

            Section("Levels") {
                ForEach([Level.debug, .info, .error], id: \.self) { level in
                    Toggle(isOn: binding(for: level)) {
                        HStack {
                            LevelBadge(level: level)
                            Text(name(for: level))
                        }
                    }
                }
            }

            Section("Status") {
                LabeledContent("Messages", value: "\(store.highlightedEntries.count) / \(store.entries.count)")

                HStack(spacing: 6) {
                    Circle()
                        .fill(store.isWatching ? .green : .secondary)
                        .frame(width: 8, height: 8)
                    Text(store.isWatching ? "Watching" : "Idle")
                        .foregroundStyle(.secondary)
                }

                if let directory = store.directory {
                    LabeledContent("Folder") {
                        Button {
                            NSWorkspace.shared.activateFileViewerSelecting([directory])
                        } label: {
                            Text(directory.lastPathComponent)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .foregroundStyle(.tint)
                        }
                        .buttonStyle(.plain)
                        .help(directory.path)
                    }
                }

                if let error = store.lastError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
    }

    ///
    /// Build a `Bool` binding into a single membership of `store.levelFilter` so each row's `Toggle` reads and mutates the right element of the set.
    ///
    private func binding(for level: Level) -> Binding<Bool> {
        Binding(
            get: { store.levelFilter.contains(level) },
            set: { include in
                if include {
                    store.levelFilter.insert(level)
                } else {
                    store.levelFilter.remove(level)
                }
            }
        )
    }

    ///
    /// Display name for a level next to its `LevelBadge` in the toggle row.
    ///
    private func name(for level: Level) -> String {
        switch level {
            case .debug: "Debug"
            case .info: "Info"
            case .error: "Error"
        }
    }

    ///
    /// Compact text describing how many entries currently satisfy every active rule. Shown next to the Previous/Next match buttons.
    ///
    private var matchSummary: String {
        let count = store.matchingEntries.count

        if store.activeFilterRules.isEmpty {
            return "No matches"
        }

        if count == 1 {
            return "1 match"
        }

        return "\(count) matches"
    }

    ///
    /// Append a fresh placeholder rule (`.any` / `.contains` / `""`) at the bottom of `filterRules`. Wired to the section header's "+" button so it always extends the list at the end, no matter where the user's caret is.
    ///
    private func appendRule() {
        store.filterRules.append(FilterRule())
    }

    ///
    /// Remove the rule with the given id. Wired to the leading "−" button in `FilterRuleRow`. Replenishes a fresh placeholder if the removal would empty `filterRules`, so the sidebar always renders at least one search-ready row.
    ///
    private func removeRule(_ id: FilterRule.ID) {
        store.filterRules.removeAll { $0.id == id }

        if store.filterRules.isEmpty {
            store.filterRules.append(FilterRule())
        }
    }

    ///
    /// Post the Next-match notification, which `ContentView` translates into a selection update.
    ///
    private func nextMatch() {
        NotificationCenter.default.post(name: .riverviewNextMatch, object: nil)
    }

    ///
    /// Post the Previous-match notification, which `ContentView` translates into a selection update.
    ///
    private func previousMatch() {
        NotificationCenter.default.post(name: .riverviewPreviousMatch, object: nil)
    }
}
