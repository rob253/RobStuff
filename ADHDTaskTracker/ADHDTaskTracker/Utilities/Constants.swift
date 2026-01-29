import Foundation

/// App-wide constants and configuration values
struct Constants {
    // MARK: - App Info

    static let appName = "ADHD Task Tracker"
    static let appVersion = "1.0.0"

    // MARK: - Notification Settings

    /// Available notification timing options (in minutes before due date)
    static let notificationTimingOptions: [NotificationTiming] = [
        NotificationTiming(minutes: 0, label: "At due time"),
        NotificationTiming(minutes: 15, label: "15 minutes before"),
        NotificationTiming(minutes: 30, label: "30 minutes before"),
        NotificationTiming(minutes: 60, label: "1 hour before"),
        NotificationTiming(minutes: 120, label: "2 hours before"),
        NotificationTiming(minutes: 1440, label: "1 day before"),
    ]

    /// Default notification timing (15 minutes before)
    static let defaultNotificationMinutes: Int32 = 15

    // MARK: - Recurring Patterns

    /// Available recurring patterns for tasks
    static let recurringPatterns: [RecurringPatternOption] = [
        RecurringPatternOption(pattern: "daily", label: "Daily", description: "Repeats every day"),
        RecurringPatternOption(pattern: "weekly", label: "Weekly", description: "Repeats every week"),
        RecurringPatternOption(pattern: "biweekly", label: "Bi-weekly", description: "Repeats every 2 weeks"),
        RecurringPatternOption(pattern: "monthly", label: "Monthly", description: "Repeats every month"),
    ]

    // MARK: - Priority Levels

    /// Priority level definitions
    static let priorities: [PriorityLevel] = [
        PriorityLevel(value: 0, label: "Low", icon: "arrow.down.circle"),
        PriorityLevel(value: 1, label: "Medium", icon: "equal.circle"),
        PriorityLevel(value: 2, label: "High", icon: "arrow.up.circle"),
    ]

    // MARK: - Animation Durations

    /// Duration for completion checkmark animation
    static let completionAnimationDuration: Double = 0.4

    /// Duration for haptic feedback delay
    static let hapticFeedbackDelay: Double = 0.1

    // MARK: - UI Constants

    /// Corner radius for cards
    static let cardCornerRadius: CGFloat = 16

    /// Corner radius for buttons
    static let buttonCornerRadius: CGFloat = 12

    /// Standard padding
    static let standardPadding: CGFloat = 16

    /// Small padding
    static let smallPadding: CGFloat = 8

    /// Task row height minimum
    static let taskRowMinHeight: CGFloat = 60

    // MARK: - Date Formatting

    /// Standard date formatter for display
    static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    /// Short date formatter (for calendar view)
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    /// Time only formatter
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    /// Relative date formatter for "due in 2 hours" style text
    static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
}

// MARK: - Supporting Types

/// Represents a notification timing option
struct NotificationTiming: Identifiable, Hashable {
    let id = UUID()
    let minutes: Int
    let label: String
}

/// Represents a recurring pattern option
struct RecurringPatternOption: Identifiable, Hashable {
    let id = UUID()
    let pattern: String
    let label: String
    let description: String
}

/// Represents a priority level
struct PriorityLevel: Identifiable, Hashable {
    let id = UUID()
    let value: Int
    let label: String
    let icon: String
}
