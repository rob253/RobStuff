import SwiftUI

/// AppColors provides a calming, ADHD-friendly color palette
/// All colors are designed with accessibility in mind, meeting WCAG contrast standards
/// and using soft, muted tones to minimize visual overwhelm
struct AppColors {
    // MARK: - Primary Colors (Calming Blues and Greens)

    /// Primary teal color - main brand color
    /// Hex: #5E9EA0
    static let primaryTeal = Color(hex: "#5E9EA0")

    /// Soft blue for secondary elements
    /// Hex: #6B9AC4
    static let softBlue = Color(hex: "#6B9AC4")

    /// Sage green for positive feedback and completed states
    /// Hex: #B2C9AB
    static let sageGreen = Color(hex: "#B2C9AB")

    /// Light sea green for accents
    /// Hex: #7FB3A5
    static let lightSeaGreen = Color(hex: "#7FB3A5")

    // MARK: - Priority Colors (Muted, Accessible)

    /// High priority - muted coral (accessible against blue/green theme)
    /// Hex: #E07A5F
    static let priorityHigh = Color(hex: "#E07A5F")

    /// Medium priority - soft amber
    /// Hex: #E9C46A
    static let priorityMedium = Color(hex: "#E9C46A")

    /// Low priority - soft gray-blue
    /// Hex: #8FA9B8
    static let priorityLow = Color(hex: "#8FA9B8")

    // MARK: - Status Colors

    /// Overdue task color - muted red
    /// Hex: #C97064
    static let overdue = Color(hex: "#C97064")

    /// Due soon color - soft orange
    /// Hex: #D4A574
    static let dueSoon = Color(hex: "#D4A574")

    /// Completed task color - calming green
    /// Hex: #7FB3A5
    static let completed = Color(hex: "#7FB3A5")

    // MARK: - Background Colors

    /// Main background for light mode
    static let backgroundLight = Color(hex: "#F8FAFB")

    /// Main background for dark mode
    static let backgroundDark = Color(hex: "#1A1F25")

    /// Card background for light mode
    static let cardLight = Color(hex: "#FFFFFF")

    /// Card background for dark mode
    static let cardDark = Color(hex: "#252B33")

    /// Secondary background for light mode
    static let secondaryBackgroundLight = Color(hex: "#EEF2F5")

    /// Secondary background for dark mode
    static let secondaryBackgroundDark = Color(hex: "#2A323C")

    // MARK: - Text Colors

    /// Primary text for light mode
    static let textPrimaryLight = Color(hex: "#2C3E50")

    /// Primary text for dark mode
    static let textPrimaryDark = Color(hex: "#E8ECF0")

    /// Secondary text for light mode
    static let textSecondaryLight = Color(hex: "#6B7C8A")

    /// Secondary text for dark mode
    static let textSecondaryDark = Color(hex: "#9BA8B4")

    // MARK: - Tag Palette (Calming options for user-customizable tags)

    /// Available tag colors for user selection
    static let tagPalette: [Color] = [
        Color(hex: "#5E9EA0"), // Teal
        Color(hex: "#6B9AC4"), // Soft Blue
        Color(hex: "#B2C9AB"), // Sage Green
        Color(hex: "#7FB3A5"), // Light Sea Green
        Color(hex: "#9DB4C0"), // Steel Blue
        Color(hex: "#A7C4BC"), // Cambridge Blue
        Color(hex: "#C2B8A3"), // Warm Gray
        Color(hex: "#D4B8A0"), // Soft Tan
        Color(hex: "#C9ADA7"), // Dusty Rose
        Color(hex: "#B8B8D1"), // Soft Lavender
        Color(hex: "#A8C686"), // Moss Green
        Color(hex: "#8FBCBB"), // Frost
    ]

    /// Tag palette hex values for Core Data storage
    static let tagPaletteHex: [String] = [
        "#5E9EA0",
        "#6B9AC4",
        "#B2C9AB",
        "#7FB3A5",
        "#9DB4C0",
        "#A7C4BC",
        "#C2B8A3",
        "#D4B8A0",
        "#C9ADA7",
        "#B8B8D1",
        "#A8C686",
        "#8FBCBB",
    ]
}

// MARK: - Color Extension for Hex Support

extension Color {
    /// Initialize a Color from a hex string
    /// - Parameter hex: A hex color string (with or without # prefix)
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Convert Color to hex string for storage
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }

        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)

        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - Adaptive Colors (Environment-Aware)

extension AppColors {
    /// Returns the appropriate background color based on color scheme
    static func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? backgroundDark : backgroundLight
    }

    /// Returns the appropriate card background color based on color scheme
    static func cardBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? cardDark : cardLight
    }

    /// Returns the appropriate secondary background color based on color scheme
    static func secondaryBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? secondaryBackgroundDark : secondaryBackgroundLight
    }

    /// Returns the appropriate primary text color based on color scheme
    static func textPrimary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? textPrimaryDark : textPrimaryLight
    }

    /// Returns the appropriate secondary text color based on color scheme
    static func textSecondary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? textSecondaryDark : textSecondaryLight
    }
}

// MARK: - Priority Color Helper

extension AppColors {
    /// Returns the color for a given priority level
    /// - Parameter priority: 0 = Low, 1 = Medium, 2 = High
    static func forPriority(_ priority: Int) -> Color {
        switch priority {
        case 2: return priorityHigh
        case 1: return priorityMedium
        default: return priorityLow
        }
    }

    /// Returns the priority label for a given priority level
    static func priorityLabel(_ priority: Int) -> String {
        switch priority {
        case 2: return "High"
        case 1: return "Medium"
        default: return "Low"
        }
    }
}
