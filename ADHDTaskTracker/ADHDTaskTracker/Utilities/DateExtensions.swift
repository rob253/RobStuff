import Foundation

extension Date {
    // MARK: - Day Comparisons

    /// Check if the date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Check if the date is tomorrow
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }

    /// Check if the date is in the past
    var isPast: Bool {
        self < Date()
    }

    /// Check if the date is in the current week
    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }

    // MARK: - Start of Day/Week/Month

    /// Start of the current day
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// End of the current day (11:59:59 PM)
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    /// Start of the week containing this date
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }

    /// End of the week containing this date
    var endOfWeek: Date {
        var components = DateComponents()
        components.weekOfYear = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfWeek) ?? self
    }

    /// Start of the month containing this date
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }

    /// End of the month containing this date
    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth) ?? self
    }

    // MARK: - Recurring Date Calculation

    /// Calculate the next occurrence based on a recurring pattern
    /// - Parameters:
    ///   - pattern: The recurring pattern (daily, weekly, biweekly, monthly)
    ///   - interval: How many units to skip (e.g., 2 for every other day)
    /// - Returns: The next occurrence date
    func nextOccurrence(pattern: String, interval: Int = 1) -> Date {
        let calendar = Calendar.current
        var components = DateComponents()

        switch pattern {
        case "daily":
            components.day = interval
        case "weekly":
            components.weekOfYear = interval
        case "biweekly":
            components.weekOfYear = 2 * interval
        case "monthly":
            components.month = interval
        default:
            components.day = 1
        }

        return calendar.date(byAdding: components, to: self) ?? self
    }

    // MARK: - Formatting

    /// Format as a relative date string (e.g., "in 2 hours", "yesterday")
    var relativeString: String {
        Constants.relativeDateFormatter.localizedString(for: self, relativeTo: Date())
    }

    /// Format for display in task lists
    var displayString: String {
        if isToday {
            return "Today, \(Constants.timeFormatter.string(from: self))"
        } else if isTomorrow {
            return "Tomorrow, \(Constants.timeFormatter.string(from: self))"
        } else if isThisWeek {
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEEE, h:mm a"
            return dayFormatter.string(from: self)
        } else {
            return Constants.displayDateFormatter.string(from: self)
        }
    }

    /// Short format for calendar views
    var shortDisplayString: String {
        Constants.shortDateFormatter.string(from: self)
    }

    /// Time only string
    var timeString: String {
        Constants.timeFormatter.string(from: self)
    }

    // MARK: - Week Days

    /// Get all days in the week containing this date
    var daysInWeek: [Date] {
        let calendar = Calendar.current
        let startOfWeek = self.startOfWeek
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }

    /// Get the day of week (1 = Sunday, 7 = Saturday)
    var dayOfWeek: Int {
        Calendar.current.component(.weekday, from: self)
    }

    /// Get the day name (e.g., "Monday")
    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }

    /// Get the short day name (e.g., "Mon")
    var shortDayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }

    /// Get the day number (e.g., "15")
    var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: self)
    }

    // MARK: - Same Day Check

    /// Check if two dates are on the same day
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    // MARK: - Days From Today

    /// Number of days from today (positive for future, negative for past)
    var daysFromToday: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: self)
        return calendar.dateComponents([.day], from: today, to: target).day ?? 0
    }
}

// MARK: - Calendar Helpers

extension Calendar {
    /// Generate dates for a calendar month view
    /// - Parameter date: A date within the month
    /// - Returns: Array of dates including leading/trailing days from adjacent months
    func generateDates(for date: Date) -> [Date] {
        guard let monthInterval = self.dateInterval(of: .month, for: date),
              let monthFirstWeek = self.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = self.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1) else {
            return []
        }

        var dates: [Date] = []
        var currentDate = monthFirstWeek.start

        while currentDate < monthLastWeek.end {
            dates.append(currentDate)
            guard let nextDate = self.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }

        return dates
    }
}
