// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import SwiftUI

///
/// Trailing-edge tick gutter overlaid on each scroll container in the outline, table, and timeline views. Mirrors the issue indicator strip in Xcode's editor: every match contributes a short horizontal tick at a position proportional to its index in the underlying list, so the user can see at a glance where matches cluster within a long log.
///
/// The view is purely decorative — `.allowsHitTesting(false)` makes sure clicks fall through to the scroll content. Because SwiftUI's `List`, `Table`, and `ScrollView` don't expose their underlying `NSScrollView`, the indicator is positioned alongside the scroll bar rather than inside it; callers attach it via `.overlay(alignment: .trailing)` on their scroll container.
///
struct MatchScrollIndicator: View {
    ///
    /// Total number of items in the displayed list. Used as the denominator when mapping each match index to a vertical position.
    ///
    let totalCount: Int

    ///
    /// Indices of matching items within the displayed list, in display order. A typical list of `LoadedMessage` matches in chronological order; for the timeline this is a list of activity indices instead.
    ///
    let matchPositions: [Int]

    ///
    /// Index of the currently selected match within the same list, or `nil` if the user's selection isn't on a match. Drawn brighter and slightly wider so the user can see which tick they're standing on.
    ///
    let selectedPosition: Int?

    private static let trackWidth: CGFloat = 12
    private static let tickWidth: CGFloat = 8
    private static let tickHeight: CGFloat = 2

    var body: some View {
        Canvas { context, size in
            guard totalCount > 0, !matchPositions.isEmpty else {
                return
            }

            let denominator = CGFloat(max(totalCount - 1, 1))
            let rightEdge = size.width - 2

            for index in matchPositions {
                let normalized = CGFloat(index) / denominator
                let y = clamped(normalized * size.height, lower: 1, upper: size.height - 1)
                let rect = CGRect(x: rightEdge - Self.tickWidth, y: y - Self.tickHeight / 2, width: Self.tickWidth, height: Self.tickHeight)
                let path = Path(roundedRect: rect, cornerRadius: Self.tickHeight / 2)
                context.fill(path, with: .color(.accentColor.opacity(0.55)))
            }

            if let selected = selectedPosition {
                let normalized = CGFloat(selected) / denominator
                let y = clamped(normalized * size.height, lower: 1, upper: size.height - 1)
                let rect = CGRect(x: rightEdge - Self.tickWidth - 2, y: y - Self.tickHeight, width: Self.tickWidth + 2, height: Self.tickHeight * 2)
                let path = Path(roundedRect: rect, cornerRadius: Self.tickHeight)
                context.fill(path, with: .color(.accentColor))
            }
        }
        .frame(width: Self.trackWidth)
        .allowsHitTesting(false)
    }

    private func clamped(_ value: CGFloat, lower: CGFloat, upper: CGFloat) -> CGFloat {
        max(lower, min(upper, value))
    }
}
