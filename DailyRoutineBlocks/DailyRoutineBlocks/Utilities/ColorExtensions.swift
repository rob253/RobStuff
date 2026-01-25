//
//  ColorExtensions.swift
//  DailyRoutineBlocks
//

import SwiftUI

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        let length = hexSanitized.count

        switch length {
        case 6:
            self.init(
                red: Double((rgb & 0xFF0000) >> 16) / 255.0,
                green: Double((rgb & 0x00FF00) >> 8) / 255.0,
                blue: Double(rgb & 0x0000FF) / 255.0
            )
        case 8:
            self.init(
                red: Double((rgb & 0xFF000000) >> 24) / 255.0,
                green: Double((rgb & 0x00FF0000) >> 16) / 255.0,
                blue: Double((rgb & 0x0000FF00) >> 8) / 255.0,
                opacity: Double(rgb & 0x000000FF) / 255.0
            )
        default:
            return nil
        }
    }

    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else {
            return nil
        }

        let r = components[0]
        let g = components.count > 1 ? components[1] : r
        let b = components.count > 2 ? components[2] : r

        return String(
            format: "#%02X%02X%02X",
            Int(r * 255),
            Int(g * 255),
            Int(b * 255)
        )
    }

    var isLight: Bool {
        guard let components = UIColor(self).cgColor.components else {
            return false
        }

        let r = components[0]
        let g = components.count > 1 ? components[1] : r
        let b = components.count > 2 ? components[2] : r

        let brightness = (r * 299 + g * 587 + b * 114) / 1000
        return brightness > 0.5
    }

    var contrastingTextColor: Color {
        isLight ? .black : .white
    }

    func adjustBrightness(by amount: Double) -> Color {
        guard let components = UIColor(self).cgColor.components else {
            return self
        }

        let r = min(max(components[0] + amount, 0), 1)
        let g = min(max((components.count > 1 ? components[1] : components[0]) + amount, 0), 1)
        let b = min(max((components.count > 2 ? components[2] : components[0]) + amount, 0), 1)

        return Color(red: r, green: g, blue: b)
    }
}

// MARK: - Theme Colors

extension Color {
    static let timelineBackground = Color(.systemBackground)
    static let timelineSecondaryBackground = Color(.secondarySystemBackground)
    static let timelineTertiaryBackground = Color(.tertiarySystemBackground)

    static let hourMarkerText = Color(.secondaryLabel)
    static let gridLine = Color(.separator).opacity(0.3)
    static let currentTimeIndicator = Color.red

    static let blockShadow = Color.black.opacity(0.1)
}
