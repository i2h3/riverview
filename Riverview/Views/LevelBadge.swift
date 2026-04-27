// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import Rivers
import SwiftUI

struct LevelBadge: View {
    let level: Level

    var body: some View {
        Text(label)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color, in: Capsule())
    }

    private var label: String {
        switch level {
            case .debug: "DEBUG"
            case .info: "INFO"
            case .error: "ERROR"
        }
    }

    private var color: Color {
        switch level {
            case .debug: .gray
            case .info: .blue
            case .error: .red
        }
    }
}

extension Level {
    var sortRank: Int {
        switch self {
            case .debug: 0
            case .info: 1
            case .error: 2
        }
    }
}
