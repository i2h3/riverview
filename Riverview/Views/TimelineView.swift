// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import AppKit
import Rivers
import SwiftUI

///
/// The Gantt-style upper half of `ContentView`'s timeline mode. Shows one row per `TimelineActivity` (produced by `TimelineActivity.aggregate(from:)`), with horizontal position and width derived from each activity's `start` and `end` times.
///
/// The horizontal scale (`pointsPerSecond`) is computed each render from the viewport width so the full activity range fits exactly without manual zoom; the user pinches to multiply that base scale via `zoomFactor`. Selecting a time range by drag updates `selectedRange`, which `ContentView` uses to filter the table below the timeline. Selecting an activity (by clicking a bar or anywhere in its row) updates `selection`, the same `LoadedMessage.ID?` used by every other view in the app.
///
/// The ruler at the top is pinned via `LazyVStack(pinnedViews: [.sectionHeaders])` so it stays visible while scrolling vertically; its background uses the toolbar `.bar` material so it visually matches the window chrome.
///
struct TimelineView: View {
    ///
    /// All activities to display, already aggregated and sorted by start time. Comes from `TimelineActivity.aggregate(from: store.filteredEntries)` in `ContentView`.
    ///
    let activities: [TimelineActivity]

    ///
    /// Levels the user has enabled in `FilterSidebar`. Bars at other levels are still rendered but dimmed so the user can see them in context.
    ///
    let highlightedLevels: Set<Level>

    ///
    /// The currently selected entry. Shared across outline, flat, timeline, and the inspector pane so selection follows the user across view modes.
    ///
    @Binding var selection: LoadedMessage.ID?

    ///
    /// The user's current time-range selection within this timeline, or `nil` if none. `ContentView` filters the lower table by this range when the user is in timeline mode.
    ///
    @Binding var selectedRange: ClosedRange<Date>?

    ///
    /// User-controlled zoom multiplier. `1.0` means "fit the full activity span to the viewport"; pinching multiplies it. The actual `pointsPerSecond` is derived from this each render, so resizing the window or new activities arriving rescales automatically while preserving the user's relative zoom.
    ///
    @State private var zoomFactor: CGFloat = 1.0

    ///
    /// Snapshot of `zoomFactor` taken at the start of a pinch gesture. The gesture's reported `magnification` is multiplied against this to produce the new factor; cleared when the gesture ends.
    ///
    @State private var pinchBaselineFactor: CGFloat?

    ///
    /// `id` of the activity whose popover is currently shown, or `nil`. At most one popover is open at a time; setting this to a new ID closes any other popover by virtue of the `Binding` plumbing in `bar(for:index:bounds:pps:)`.
    ///
    @State private var popoverID: TimelineActivity.ID?

    private static let rowHeight: CGFloat = 22
    private static let rowSpacing: CGFloat = 3
    private static let rulerHeight: CGFloat = 22
    private static let horizontalPadding: CGFloat = 8
    private static let bottomPadding: CGFloat = 12
    private static let minPointsPerSecond: CGFloat = 0.001
    private static let maxPointsPerSecond: CGFloat = 100_000
    private static let internalLabelPadding: CGFloat = 12
    private static let externalLabelSpacing: CGFloat = 4
    private static let labelFont: NSFont = .preferredFont(forTextStyle: .caption1)

    var body: some View {
        content
    }

    // MARK: - Layout

    @ViewBuilder
    private var content: some View {
        if let bounds = globalBounds {
            GeometryReader { proxy in
                let pps = pointsPerSecond(viewportWidth: proxy.size.width, bounds: bounds)
                let totalWidth = totalWidth(for: bounds, viewportWidth: proxy.size.width, pps: pps)
                let rowsHeight = max(rowsContentHeight, proxy.size.height - Self.rulerHeight)

                ScrollView([.horizontal, .vertical]) {
                    LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                        Section {
                            rowsLayer(bounds: bounds, totalWidth: totalWidth, height: rowsHeight, pps: pps)
                        } header: {
                            rulerHeader(bounds: bounds, totalWidth: totalWidth, pps: pps)
                        }
                    }
                }
                .simultaneousGesture(magnifyGesture)
            }
        } else {
            ContentUnavailableView("Nothing on the timeline", systemImage: "chart.bar.xaxis")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func rulerHeader(bounds: ClosedRange<Date>, totalWidth: CGFloat, pps: CGFloat) -> some View {
        rulerCanvas(bounds: bounds, totalWidth: totalWidth, pps: pps)
            .contentShape(Rectangle())
            .gesture(rangeDragGesture(bounds: bounds, pps: pps))
    }

    private func rowsLayer(bounds: ClosedRange<Date>, totalWidth: CGFloat, height: CGFloat, pps: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Color.clear
                .frame(width: totalWidth, height: height)
                .contentShape(Rectangle())
                .gesture(rangeDragGesture(bounds: bounds, pps: pps))
                .onTapGesture {
                    popoverID = nil
                    selectedRange = nil
                }

            ForEach(Array(activities.enumerated()), id: \.element.id) { index, activity in
                rowHighlight(for: activity, index: index, totalWidth: totalWidth)
            }

            ForEach(Array(activities.enumerated()), id: \.element.id) { index, activity in
                rowHitArea(for: activity, index: index, bounds: bounds, totalWidth: totalWidth, pps: pps)
            }

            ForEach(Array(activities.enumerated()), id: \.element.id) { index, activity in
                bar(for: activity, index: index, bounds: bounds, pps: pps)
            }

            rangeOverlay(bounds: bounds, height: height, pps: pps)
        }
        .frame(width: totalWidth, height: height, alignment: .topLeading)
    }

    @ViewBuilder
    private func rowHighlight(for activity: TimelineActivity, index: Int, totalWidth: CGFloat) -> some View {
        if isSelected(activity) {
            let yPos = CGFloat(index) * (Self.rowHeight + Self.rowSpacing)

            Rectangle()
                .fill(Color.accentColor.opacity(0.10))
                .frame(width: totalWidth, height: Self.rowHeight)
                .position(x: totalWidth / 2, y: yPos + Self.rowHeight / 2)
                .allowsHitTesting(false)
        }
    }

    private func rowHitArea(for activity: TimelineActivity, index: Int, bounds: ClosedRange<Date>, totalWidth: CGFloat, pps: CGFloat) -> some View {
        let yPos = CGFloat(index) * (Self.rowHeight + Self.rowSpacing)

        return Color.clear
            .frame(width: totalWidth, height: Self.rowHeight)
            .contentShape(Rectangle())
            .onTapGesture {
                selection = activity.primaryEntry.id
                popoverID = nil
            }
            .simultaneousGesture(rangeDragGesture(bounds: bounds, pps: pps))
            .position(x: totalWidth / 2, y: yPos + Self.rowHeight / 2)
    }

    @ViewBuilder
    private func bar(for activity: TimelineActivity, index: Int, bounds: ClosedRange<Date>, pps: CGFloat) -> some View {
        let xPos = x(for: activity.start, bounds: bounds, pps: pps)
        let yPos = CGFloat(index) * (Self.rowHeight + Self.rowSpacing)
        let barW = width(for: activity, pps: pps)
        let labelW = textWidth(activity.label)
        let labelFitsInside = labelW + Self.internalLabelPadding <= barW
        let externalLabelWidth: CGFloat? = labelFitsInside ? nil : labelW
        let totalW: CGFloat = if let externalLabelWidth {
            barW + Self.externalLabelSpacing + externalLabelWidth
        } else {
            barW
        }

        TimelineActivityBar(
            activity: activity,
            barWidth: barW,
            height: Self.rowHeight,
            externalLabelWidth: externalLabelWidth,
            externalLabelSpacing: Self.externalLabelSpacing,
            isHighlighted: highlightedLevels.contains(activity.level),
            isSelected: isSelected(activity),
            isPopoverPresented: Binding(
                get: { popoverID == activity.id },
                set: { isShown in
                    if !isShown, popoverID == activity.id {
                        popoverID = nil
                    }
                }
            ),
            onTap: {
                if popoverID == activity.id {
                    popoverID = nil
                } else {
                    selection = activity.primaryEntry.id
                    popoverID = activity.id
                }
            }
        )
        .position(x: xPos + totalW / 2, y: yPos + Self.rowHeight / 2)
    }

    private func rulerCanvas(bounds: ClosedRange<Date>, totalWidth: CGFloat, pps: CGFloat) -> some View {
        Canvas { ctx, size in
            let span = bounds.upperBound.timeIntervalSince(bounds.lowerBound)
            let step = niceStep(for: pps)

            var t: TimeInterval = 0

            while t <= span + 0.5 * step {
                let xPos = Self.horizontalPadding + CGFloat(t) * pps

                var tick = Path()
                tick.move(to: CGPoint(x: xPos, y: size.height - 6))
                tick.addLine(to: CGPoint(x: xPos, y: size.height))
                ctx.stroke(tick, with: .color(.gray.opacity(0.55)), lineWidth: 1)

                let date = bounds.lowerBound.addingTimeInterval(t)
                let label = tickLabel(date: date, step: step)
                let text = Text(label).font(.caption2).foregroundStyle(.secondary)
                ctx.draw(text, at: CGPoint(x: xPos + 3, y: 2), anchor: .topLeading)

                t += step
            }

            var bottom = Path()
            bottom.move(to: CGPoint(x: 0, y: size.height - 0.5))
            bottom.addLine(to: CGPoint(x: size.width, y: size.height - 0.5))
            ctx.stroke(bottom, with: .color(.gray.opacity(0.4)), lineWidth: 1)
        }
        .frame(width: totalWidth, height: Self.rulerHeight)
        .background(.bar)
    }

    @ViewBuilder
    private func rangeOverlay(bounds: ClosedRange<Date>, height: CGFloat, pps: CGFloat) -> some View {
        if let range = selectedRange {
            let startX = x(for: range.lowerBound, bounds: bounds, pps: pps)
            let endX = x(for: range.upperBound, bounds: bounds, pps: pps)
            let w = max(2, endX - startX)

            Rectangle()
                .fill(Color.accentColor.opacity(0.18))
                .overlay(alignment: .leading) {
                    Rectangle().fill(Color.accentColor).frame(width: 1)
                }
                .overlay(alignment: .trailing) {
                    Rectangle().fill(Color.accentColor).frame(width: 1)
                }
                .frame(width: w, height: height, alignment: .topLeading)
                .position(x: startX + w / 2, y: height / 2)
                .allowsHitTesting(false)
        }
    }

    // MARK: - Gestures

    private var magnifyGesture: some Gesture {
        MagnifyGesture(minimumScaleDelta: 0.005)
            .onChanged { value in
                let baseline = pinchBaselineFactor ?? zoomFactor
                pinchBaselineFactor = baseline
                zoomFactor = max(0.001, baseline * value.magnification)
            }
            .onEnded { _ in
                pinchBaselineFactor = nil
            }
    }

    private func rangeDragGesture(bounds: ClosedRange<Date>, pps: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                let s = date(at: value.startLocation.x, bounds: bounds, pps: pps)
                let e = date(at: value.location.x, bounds: bounds, pps: pps)
                let lo = min(s, e)
                let hi = max(s, e)
                selectedRange = lo ... hi
            }
            .onEnded { _ in
                if let range = selectedRange,
                   range.upperBound.timeIntervalSince(range.lowerBound) < 0.0005
                {
                    selectedRange = nil
                }
            }
    }

    // MARK: - Geometry

    private func pointsPerSecond(viewportWidth: CGFloat, bounds: ClosedRange<Date>) -> CGFloat {
        let span = bounds.upperBound.timeIntervalSince(bounds.lowerBound)

        guard span > 0, viewportWidth > 0 else { return 60 }

        let usable = max(1, viewportWidth - Self.horizontalPadding * 2)
        let basePPS = usable / CGFloat(span)
        let target = basePPS * zoomFactor
        return min(max(target, Self.minPointsPerSecond), Self.maxPointsPerSecond)
    }

    private func totalWidth(for bounds: ClosedRange<Date>, viewportWidth: CGFloat, pps: CGFloat) -> CGFloat {
        let spanSeconds = bounds.upperBound.timeIntervalSince(bounds.lowerBound)
        var maxRightEdge = Self.horizontalPadding + CGFloat(spanSeconds) * pps

        for activity in activities {
            let xStart = x(for: activity.start, bounds: bounds, pps: pps)
            let barW = width(for: activity, pps: pps)
            let labelW = textWidth(activity.label)
            let rightEdge: CGFloat = if labelW + Self.internalLabelPadding <= barW {
                xStart + barW
            } else {
                xStart + barW + Self.externalLabelSpacing + labelW
            }

            if rightEdge > maxRightEdge {
                maxRightEdge = rightEdge
            }
        }

        return max(viewportWidth, maxRightEdge + Self.horizontalPadding)
    }

    private var rowsContentHeight: CGFloat {
        CGFloat(activities.count) * (Self.rowHeight + Self.rowSpacing) + Self.bottomPadding
    }

    private var globalBounds: ClosedRange<Date>? {
        guard !activities.isEmpty else { return nil }

        let starts = activities.map(\.start)
        let ends = activities.map(\.end)

        guard let first = starts.min(), let last = ends.max() else { return nil }

        let safeEnd = last > first ? last : first.addingTimeInterval(1)
        return first ... safeEnd
    }

    private func x(for date: Date, bounds: ClosedRange<Date>, pps: CGFloat) -> CGFloat {
        let clamped = min(max(date, bounds.lowerBound), bounds.upperBound)
        return Self.horizontalPadding + CGFloat(clamped.timeIntervalSince(bounds.lowerBound)) * pps
    }

    private func date(at x: CGFloat, bounds: ClosedRange<Date>, pps: CGFloat) -> Date {
        let offset = max(0, x - Self.horizontalPadding)
        let seconds = TimeInterval(offset / pps)
        let raw = bounds.lowerBound.addingTimeInterval(seconds)
        return min(max(raw, bounds.lowerBound), bounds.upperBound)
    }

    private func width(for activity: TimelineActivity, pps: CGFloat) -> CGFloat {
        max(4, CGFloat(activity.duration) * pps)
    }

    private func textWidth(_ text: String) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [.font: Self.labelFont]
        return ceil((text as NSString).size(withAttributes: attributes).width)
    }

    // MARK: - Selection helpers

    private func isSelected(_ activity: TimelineActivity) -> Bool {
        guard let selection else { return false }
        return activity.entries.contains { $0.id == selection }
    }

    // MARK: - Ruler labelling

    private func niceStep(for pointsPerSecond: CGFloat) -> TimeInterval {
        let minPixelGap: CGFloat = 80
        let minTimeGap = TimeInterval(minPixelGap / pointsPerSecond)
        let candidates: [TimeInterval] = [
            0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5,
            1, 2, 5, 10, 30, 60, 120, 300, 600, 1800, 3600
        ]
        return candidates.first { $0 >= minTimeGap } ?? max(minTimeGap, 1)
    }

    private func tickLabel(date: Date, step: TimeInterval) -> String {
        if step < 1 {
            return Self.fineFormatter.string(from: date)
        }

        return Self.coarseFormatter.string(from: date)
    }

    private static let fineFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    private static let coarseFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}
