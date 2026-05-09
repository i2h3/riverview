// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import SwiftUI

///
/// One editable `FilterRule` in `FilterSidebar`. Renders as a horizontal `[−] [Subject ▾] [Operator ▾] [Value]` stack — the per-row "+" from the original Mail.app layout has been hoisted into the section header so adding always appends at the bottom of the list rather than relative to a particular row.
///
/// Both popups use `Picker(.menu)` so they collapse to compact pulldowns even at the sidebar's narrow width. The remove button is disabled when this row is the only remaining rule and is already in its placeholder state — there is nothing to remove or reset in that case. When it is the only row but the user has customised it, the button instead resets it to the placeholder via `FilterSidebar.removeRule(_:)`'s replenishment path, so the sidebar always shows at least one search-ready row.
///
struct FilterRuleRow: View {
    ///
    /// Two-way binding to the rule this row edits. Held by `JournalStore.filterRules` and iterated by `FilterSidebar`.
    ///
    @Binding
    var rule: FilterRule

    ///
    /// `true` when removing this rule should leave at least one rule still on screen. Drives the disabled state of the remove button.
    ///
    let canRemove: Bool

    ///
    /// Invoked when the user taps the leading "−" button to remove this rule. Wired to `FilterSidebar.removeRule(_:)`.
    ///
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Button(action: onRemove) {
                Image(systemName: "minus.circle.fill")
            }
            .buttonStyle(.borderless)
            .disabled(!canRemove)
            .help("Remove this rule")

            Picker("Subject", selection: $rule.subject) {
                ForEach(FilterSubject.allCases) { subject in
                    Text(subject.localizedTitle).tag(subject)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .fixedSize()

            Picker("Operator", selection: $rule.op) {
                ForEach(FilterOperator.allCases) { op in
                    Text(op.localizedTitle).tag(op)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .fixedSize()

            TextField("Value", text: $rule.value)
                .textFieldStyle(.roundedBorder)
                .labelsHidden()
        }
    }
}

#Preview {
    NavigationSplitView {
        Form {
            Section {
                FilterRuleRow(rule: .constant(FilterRule(id: UUID(), subject: .any, op: .contains, value: "Test")), canRemove: false, onRemove: {})
                FilterRuleRow(rule: .constant(FilterRule(id: UUID(), subject: .label, op: .beginsWith, value: "Test")), canRemove: true, onRemove: {})
            } header: {
                HStack {
                    Text("Filters")

                    Button {
                        //
                    } label: {
                        Label("Add Filter", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.secondary)

                    Spacer()
                }
            }

            Spacer()
        }
        .formStyle(.grouped)
        .navigationSplitViewColumnWidth(min: 300, ideal: 300)
    } detail: {
        ContentUnavailableView("Nothing to see here", systemImage: "face.smiling")
    }
    .frame(width: 800)
}
