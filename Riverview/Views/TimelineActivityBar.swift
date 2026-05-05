// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import SwiftUI

///
/// A single Gantt-style bar in `TimelineView` representing one activity. The bar's width is set by the activity's duration scaled by `pointsPerSecond` in the parent view; the bar's color is derived from the activity's dominant `Level`.
///
/// When the activity's label fits within the bar at the current zoom, the label is drawn inside the bar in white. When it does not fit, the parent supplies an `externalLabelWidth` and the label is drawn trailing the bar in the secondary text color so the user can still tell what each bar represents.
///
/// Tapping the bar invokes `onTap`, which the parent uses to update the selection and toggle the popover. The popover binding (`isPopoverPresented`) is anchored to this view so it appears next to the tapped bar.
///
struct TimelineActivityBar: View {
    ///
    /// The activity this bar represents. Provides the label, level, and primary entry shown in the popover.
    ///
    let activity: TimelineActivity

    ///
    /// Width of the bar itself, in points. Computed by the parent as `activity.duration * pointsPerSecond`, clamped to a minimum so instantaneous activities still render as a visible tick.
    ///
    let barWidth: CGFloat

    ///
    /// Height of the bar, matching the row height defined in the parent timeline.
    ///
    let height: CGFloat

    ///
    /// When non-`nil`, the activity's label does not fit inside the bar at the current zoom and is rendered trailing the bar with this width. The trailing label uses the secondary text style.
    ///
    let externalLabelWidth: CGFloat?

    ///
    /// Spacing between the bar and the trailing label when `externalLabelWidth` is set. Ignored otherwise.
    ///
    let externalLabelSpacing: CGFloat

    ///
    /// Whether the activity's level is included in the user's level filter (`JournalStore.levelFilter`). Bars whose level is filtered out are dimmed so the user can still see them in context but they recede visually.
    ///
    let isHighlighted: Bool

    ///
    /// Whether any of the activity's entries is the current `selection`. Selected bars get an accent-colored stroke.
    ///
    let isSelected: Bool

    ///
    /// Two-way binding driving the popover. The parent stores at most one popover ID at a time; this binding reflects "is the parent's `popoverID` equal to this activity's `id`?".
    ///
    @Binding var isPopoverPresented: Bool

    ///
    /// Closure invoked when the user clicks the bar (or the trailing external label, since they share a single `Button`). The parent uses this to update `selection` and toggle the popover.
    ///
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: externalLabelSpacing) {
                barShape

                if let externalLabelWidth {
                    Text(activity.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(width: externalLabelWidth, height: height, alignment: .leading)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("\(activity.label) · \(activity.activity.description)")
        .popover(isPresented: $isPopoverPresented, arrowEdge: .bottom) {
            MessageInspector(entry: activity.primaryEntry)
                .frame(minWidth: 280, idealWidth: 340, minHeight: 240, idealHeight: 320)
        }
    }

    @ViewBuilder
    private var barShape: some View {
        Group {
            if externalLabelWidth == nil {
                Text(activity.label)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.horizontal, 6)
                    .frame(width: barWidth, height: height, alignment: .leading)
                    .foregroundStyle(.white)
            } else {
                Color.clear
                    .frame(width: barWidth, height: height)
            }
        }
        .background(barColor.opacity(isHighlighted ? 0.85 : 0.3), in: RoundedRectangle(cornerRadius: 4))
        .overlay {
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        }
    }

    private var barColor: Color {
        switch activity.level {
            case .debug: .gray
            case .info: .blue
            case .error: .red
        }
    }
}
