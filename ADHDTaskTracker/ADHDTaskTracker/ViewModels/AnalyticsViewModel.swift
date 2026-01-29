import Foundation
import CoreData
import SwiftUI

/// AnalyticsViewModel manages progress tracking and statistics
@MainActor
class AnalyticsViewModel: ObservableObject {
    // MARK: - Published Properties

    /// Tasks completed today
    @Published var completedToday: Int = 0

    /// Tasks completed this week
    @Published var completedThisWeek: Int = 0

    /// Tasks completed this month
    @Published var completedThisMonth: Int = 0

    /// Total tasks completed all time
    @Published var totalCompleted: Int = 0

    /// Daily completion data for charts (last 7 days)
    @Published var dailyCompletions: [DailyCompletion] = []

    /// Weekly completion data for charts (last 4 weeks)
    @Published var weeklyCompletions: [WeeklyCompletion] = []

    /// Completion breakdown by priority
    @Published var completionsByPriority: [PriorityCompletion] = []

    /// Completion breakdown by tag
    @Published var completionsByTag: [TagCompletion] = []

    /// Current streak (consecutive days with at least one completion)
    @Published var currentStreak: Int = 0

    /// Longest streak
    @Published var longestStreak: Int = 0

    /// Average tasks completed per day (last 30 days)
    @Published var averagePerDay: Double = 0.0

    /// Completion rate (completed vs total created in last 30 days)
    @Published var completionRate: Double = 0.0

    /// Loading state
    @Published var isLoading: Bool = false

    // MARK: - Dependencies

    private let viewContext: NSManagedObjectContext

    // MARK: - Initialization

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.viewContext = context
        refreshAnalytics()
    }

    // MARK: - Refresh Analytics

    /// Refresh all analytics data
    func refreshAnalytics() {
        isLoading = true

        calculateCompletionCounts()
        calculateDailyCompletions()
        calculateWeeklyCompletions()
        calculatePriorityBreakdown()
        calculateTagBreakdown()
        calculateStreaks()
        calculateAverages()

        isLoading = false
    }

    // MARK: - Completion Counts

    private func calculateCompletionCounts() {
        let request = NSFetchRequest<CompletionRecordEntity>(entityName: "CompletionRecordEntity")

        do {
            let allRecords = try viewContext.fetch(request)

            let now = Date()

            // Today
            completedToday = allRecords.filter { record in
                guard let completedAt = record.completedAt else { return false }
                return completedAt.isToday
            }.count

            // This week
            completedThisWeek = allRecords.filter { record in
                guard let completedAt = record.completedAt else { return false }
                return completedAt >= now.startOfWeek && completedAt <= now.endOfWeek
            }.count

            // This month
            completedThisMonth = allRecords.filter { record in
                guard let completedAt = record.completedAt else { return false }
                return completedAt >= now.startOfMonth && completedAt <= now.endOfMonth
            }.count

            // Total
            totalCompleted = allRecords.count

        } catch {
            print("Failed to calculate completion counts: \(error)")
        }
    }

    // MARK: - Daily Completions

    private func calculateDailyCompletions() {
        let request = NSFetchRequest<CompletionRecordEntity>(entityName: "CompletionRecordEntity")

        // Get records from the last 7 days
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -6, to: Date().startOfDay) ?? Date()
        request.predicate = NSPredicate(format: "completedAt >= %@", sevenDaysAgo as NSDate)

        do {
            let records = try viewContext.fetch(request)

            // Group by day
            var dailyCounts: [Date: Int] = [:]

            // Initialize all days with 0
            for dayOffset in 0..<7 {
                if let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: sevenDaysAgo) {
                    dailyCounts[date.startOfDay] = 0
                }
            }

            // Count completions per day
            for record in records {
                guard let completedAt = record.completedAt else { continue }
                let dayStart = completedAt.startOfDay
                dailyCounts[dayStart, default: 0] += 1
            }

            // Convert to array and sort
            dailyCompletions = dailyCounts.map { date, count in
                DailyCompletion(date: date, count: count)
            }.sorted { $0.date < $1.date }

        } catch {
            print("Failed to calculate daily completions: \(error)")
        }
    }

    // MARK: - Weekly Completions

    private func calculateWeeklyCompletions() {
        let request = NSFetchRequest<CompletionRecordEntity>(entityName: "CompletionRecordEntity")

        // Get records from the last 4 weeks
        let fourWeeksAgo = Calendar.current.date(byAdding: .weekOfYear, value: -3, to: Date().startOfWeek) ?? Date()
        request.predicate = NSPredicate(format: "completedAt >= %@", fourWeeksAgo as NSDate)

        do {
            let records = try viewContext.fetch(request)

            // Group by week
            var weeklyCounts: [Date: Int] = [:]

            // Initialize all weeks with 0
            for weekOffset in 0..<4 {
                if let date = Calendar.current.date(byAdding: .weekOfYear, value: weekOffset, to: fourWeeksAgo) {
                    weeklyCounts[date.startOfWeek] = 0
                }
            }

            // Count completions per week
            for record in records {
                guard let completedAt = record.completedAt else { continue }
                let weekStart = completedAt.startOfWeek
                weeklyCounts[weekStart, default: 0] += 1
            }

            // Convert to array and sort
            weeklyCompletions = weeklyCounts.map { date, count in
                WeeklyCompletion(weekStart: date, count: count)
            }.sorted { $0.weekStart < $1.weekStart }

        } catch {
            print("Failed to calculate weekly completions: \(error)")
        }
    }

    // MARK: - Priority Breakdown

    private func calculatePriorityBreakdown() {
        let request = NSFetchRequest<CompletionRecordEntity>(entityName: "CompletionRecordEntity")

        // Last 30 days
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        request.predicate = NSPredicate(format: "completedAt >= %@", thirtyDaysAgo as NSDate)

        do {
            let records = try viewContext.fetch(request)

            // Count by priority
            var priorityCounts: [Int16: Int] = [0: 0, 1: 0, 2: 0]

            for record in records {
                priorityCounts[record.taskPriority, default: 0] += 1
            }

            completionsByPriority = priorityCounts.map { priority, count in
                PriorityCompletion(
                    priority: TaskPriority(rawValue: priority) ?? .medium,
                    count: count
                )
            }.sorted { $0.priority.rawValue > $1.priority.rawValue }

        } catch {
            print("Failed to calculate priority breakdown: \(error)")
        }
    }

    // MARK: - Tag Breakdown

    private func calculateTagBreakdown() {
        // Fetch completed tasks with their tags
        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        request.predicate = NSPredicate(format: "isCompleted == YES")

        do {
            let completedTasks = try viewContext.fetch(request)

            // Count by tag
            var tagCounts: [String: (count: Int, color: Color)] = [:]

            for task in completedTasks {
                for tag in task.tagsArray {
                    let name = tag.name ?? "Unknown"
                    if tagCounts[name] == nil {
                        tagCounts[name] = (count: 0, color: tag.color)
                    }
                    tagCounts[name]?.count += 1
                }
            }

            completionsByTag = tagCounts.map { name, data in
                TagCompletion(tagName: name, count: data.count, color: data.color)
            }.sorted { $0.count > $1.count }

        } catch {
            print("Failed to calculate tag breakdown: \(error)")
        }
    }

    // MARK: - Streaks

    private func calculateStreaks() {
        let request = NSFetchRequest<CompletionRecordEntity>(entityName: "CompletionRecordEntity")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CompletionRecordEntity.completedAt, ascending: false)]

        do {
            let records = try viewContext.fetch(request)

            // Get unique days with completions
            var completionDays: Set<Date> = []
            for record in records {
                guard let completedAt = record.completedAt else { continue }
                completionDays.insert(completedAt.startOfDay)
            }

            let sortedDays = completionDays.sorted(by: >)

            // Calculate current streak
            var streak = 0
            var checkDate = Date().startOfDay

            // Check if there was a completion today or yesterday to start the streak
            if completionDays.contains(checkDate) {
                streak = 1
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                // Check yesterday
                let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
                if completionDays.contains(yesterday) {
                    streak = 1
                    checkDate = Calendar.current.date(byAdding: .day, value: -2, to: Date().startOfDay) ?? checkDate
                }
            }

            // Continue counting streak
            while completionDays.contains(checkDate) {
                streak += 1
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            }

            currentStreak = streak

            // Calculate longest streak
            var longest = 0
            var current = 0
            var previousDay: Date?

            for day in sortedDays {
                if let previous = previousDay {
                    let dayDiff = Calendar.current.dateComponents([.day], from: day, to: previous).day ?? 0
                    if dayDiff == 1 {
                        current += 1
                    } else {
                        longest = max(longest, current)
                        current = 1
                    }
                } else {
                    current = 1
                }
                previousDay = day
            }

            longestStreak = max(longest, current)

        } catch {
            print("Failed to calculate streaks: \(error)")
        }
    }

    // MARK: - Averages

    private func calculateAverages() {
        let request = NSFetchRequest<CompletionRecordEntity>(entityName: "CompletionRecordEntity")

        // Last 30 days
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        request.predicate = NSPredicate(format: "completedAt >= %@", thirtyDaysAgo as NSDate)

        do {
            let records = try viewContext.fetch(request)
            let completedCount = Double(records.count)

            // Average per day
            averagePerDay = completedCount / 30.0

            // Completion rate (tasks completed vs tasks created in the period)
            let taskRequest = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
            taskRequest.predicate = NSPredicate(format: "createdAt >= %@", thirtyDaysAgo as NSDate)
            let createdCount = Double(try viewContext.count(for: taskRequest))

            if createdCount > 0 {
                completionRate = min((completedCount / createdCount) * 100, 100)
            } else {
                completionRate = 0
            }

        } catch {
            print("Failed to calculate averages: \(error)")
        }
    }
}

// MARK: - Supporting Types

/// Represents daily completion data for charts
struct DailyCompletion: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int

    var dayLabel: String {
        date.shortDayName
    }
}

/// Represents weekly completion data for charts
struct WeeklyCompletion: Identifiable {
    let id = UUID()
    let weekStart: Date
    let count: Int

    var weekLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: weekStart)
    }
}

/// Represents completion data by priority
struct PriorityCompletion: Identifiable {
    let id = UUID()
    let priority: TaskPriority
    let count: Int
}

/// Represents completion data by tag
struct TagCompletion: Identifiable {
    let id = UUID()
    let tagName: String
    let count: Int
    let color: Color
}
