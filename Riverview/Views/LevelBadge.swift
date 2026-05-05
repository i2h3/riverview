// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import Rivers
import SwiftUI

///
/// A small, capsule-shaped badge displaying a `Level` ("DEBUG", "INFO", "ERROR") in its associated color. Used wherever a level needs to be shown compactly: `MessageRow`, `MessageTableView`, `MessageInspector`, and `FilterSidebar`.
///
/// The badge encapsulates the canonical color and label mapping for a level so the rest of the app stays consistent. Bars in `TimelineView` use the same color palette but render their own shapes.
///
struct LevelBadge: View {
    ///
    /// The level to display.
    ///
    let level: Level

    var body: some View {
        Text(label)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color, in: Capsule())
    }

    ///
    /// The uppercase string shown inside the badge.
    ///
    private var label: String {
        switch level {
            case .debug: "DEBUG"
            case .info: "INFO"
            case .error: "ERROR"
        }
    }

    ///
    /// The fill color of the badge. Mirrored by `TimelineActivityBar` for its bars so the timeline and other views agree visually.
    ///
    private var color: Color {
        switch level {
            case .debug: .gray
            case .info: .blue
            case .error: .red
        }
    }
}
