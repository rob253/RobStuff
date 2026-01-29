import Foundation
import CoreData
import SwiftUI

// MARK: - Task Priority Enum

/// Priority levels for tasks
enum TaskPriority: Int16, CaseIterable, Identifiable {
    case low = 0
    case medium = 1
    case high = 2

    var id: Int16 { rawValue }

    var label: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    var icon: String {
        switch self {
        case .low: return "arrow.down.circle"
        case .medium: return "equal.circle"
        case .high: return "arrow.up.circle"
        }
    }

    var color: Color {
        AppColors.forPriority(Int(rawValue))
    }
}

// MARK: - Task Status Enum

/// Current status of a task based on due date
enum TaskStatus {
    case upcoming    // More than 1 hour away
    case dueSoon     // Within 1 hour
    case overdue     // Past due date
    case completed   // Task is marked complete

    var color: Color {
        switch self {
        case .upcoming: return AppColors.primaryTeal
        case .dueSoon: return AppColors.dueSoon
        case .overdue: return AppColors.overdue
        case .completed: return AppColors.completed
        }
    }

    var label: String {
        switch self {
        case .upcoming: return "Upcoming"
        case .dueSoon: return "Due Soon"
        case .overdue: return "Overdue"
        case .completed: return "Completed"
        }
    }
}

// MARK: - TaskEntity Extensions

extension TaskEntity {
    // MARK: - Computed Properties

    /// The priority as an enum
    var taskPriority: TaskPriority {
        TaskPriority(rawValue: priority) ?? .medium
    }

    /// Current status of the task
    var status: TaskStatus {
        if isCompleted {
            return .completed
        }

        guard let dueDate = dueDate else {
            return .upcoming
        }

        let now = Date()
        if dueDate < now {
            return .overdue
        } else if dueDate.timeIntervalSince(now) < 3600 { // Within 1 hour
            return .dueSoon
        } else {
            return .upcoming
        }
    }

    /// Tags as an array for easier iteration
    var tagsArray: [TagEntity] {
        let tagSet = tags as? Set<TagEntity> ?? []
        return Array(tagSet).sorted { ($0.name ?? "") < ($1.name ?? "") }
    }

    /// Display string for the due date
    var dueDateDisplay: String {
        dueDate?.displayString ?? "No due date"
    }

    /// Relative time string (e.g., "in 2 hours")
    var relativeTimeDisplay: String {
        dueDate?.relativeString ?? ""
    }

    /// Check if task is due today
    var isDueToday: Bool {
        dueDate?.isToday ?? false
    }

    /// Check if task is due this week
    var isDueThisWeek: Bool {
        dueDate?.isThisWeek ?? false
    }

    // MARK: - Factory Methods

    /// Create a new task with default values
    static func create(
        in context: NSManagedObjectContext,
        title: String,
        description: String? = nil,
        dueDate: Date,
        priority: TaskPriority = .medium,
        tags: [TagEntity] = [],
        notificationEnabled: Bool = true,
        notificationMinutesBefore: Int32 = Constants.defaultNotificationMinutes,
        isRecurring: Bool = false,
        recurringPattern: String? = nil,
        recurringInterval: Int32 = 1,
        recurringEndDate: Date? = nil
    ) -> TaskEntity {
        let task = TaskEntity(context: context)
        task.id = UUID()
        task.title = title
        task.taskDescription = description
        task.dueDate = dueDate
        task.createdAt = Date()
        task.priority = priority.rawValue
        task.isCompleted = false
        task.notificationEnabled = notificationEnabled
        task.notificationMinutesBefore = notificationMinutesBefore
        task.isRecurring = isRecurring
        task.recurringPattern = recurringPattern
        task.recurringInterval = recurringInterval
        task.recurringEndDate = recurringEndDate
        task.tags = NSSet(array: tags)
        return task
    }

    // MARK: - Recurring Task Support

    /// Create the next instance of a recurring task
    /// - Parameter context: The managed object context
    /// - Returns: The new task instance, or nil if the recurrence has ended
    func createNextRecurrence(in context: NSManagedObjectContext) -> TaskEntity? {
        guard isRecurring,
              let pattern = recurringPattern,
              let currentDueDate = dueDate else {
            return nil
        }

        let nextDueDate = currentDueDate.nextOccurrence(pattern: pattern, interval: Int(recurringInterval))

        // Check if we've passed the end date
        if let endDate = recurringEndDate, nextDueDate > endDate {
            return nil
        }

        let nextTask = TaskEntity(context: context)
        nextTask.id = UUID()
        nextTask.title = title
        nextTask.taskDescription = taskDescription
        nextTask.dueDate = nextDueDate
        nextTask.createdAt = Date()
        nextTask.priority = priority
        nextTask.isCompleted = false
        nextTask.notificationEnabled = notificationEnabled
        nextTask.notificationMinutesBefore = notificationMinutesBefore
        nextTask.isRecurring = true
        nextTask.recurringPattern = recurringPattern
        nextTask.recurringInterval = recurringInterval
        nextTask.recurringEndDate = recurringEndDate
        nextTask.parentTaskId = id
        nextTask.tags = tags

        return nextTask
    }

    /// Toggle completion status and handle recurring tasks
    /// - Parameter context: The managed object context
    /// - Returns: The next task instance if this was a recurring task, nil otherwise
    @discardableResult
    func toggleCompletion(in context: NSManagedObjectContext) -> TaskEntity? {
        isCompleted.toggle()

        if isCompleted {
            completedAt = Date()

            // Create a completion record for analytics
            let record = CompletionRecordEntity(context: context)
            record.id = UUID()
            record.taskId = id
            record.completedAt = Date()
            record.taskTitle = title
            record.taskPriority = priority

            // If recurring, create the next instance
            if isRecurring {
                return createNextRecurrence(in: context)
            }
        } else {
            completedAt = nil
        }

        return nil
    }
}

// MARK: - Fetch Requests

extension TaskEntity {
    /// Fetch request for all incomplete tasks sorted by due date
    static func incompleteTasks() -> NSFetchRequest<TaskEntity> {
        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        request.predicate = NSPredicate(format: "isCompleted == NO")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TaskEntity.dueDate, ascending: true)
        ]
        return request
    }

    /// Fetch request for tasks due today
    static func todaysTasks() -> NSFetchRequest<TaskEntity> {
        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        let startOfDay = Date().startOfDay
        let endOfDay = Date().endOfDay
        request.predicate = NSPredicate(format: "dueDate >= %@ AND dueDate <= %@", startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TaskEntity.dueDate, ascending: true)
        ]
        return request
    }

    /// Fetch request for tasks in a specific week
    static func tasksForWeek(containing date: Date) -> NSFetchRequest<TaskEntity> {
        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        let startOfWeek = date.startOfWeek
        let endOfWeek = date.endOfWeek
        request.predicate = NSPredicate(format: "dueDate >= %@ AND dueDate <= %@", startOfWeek as NSDate, endOfWeek as NSDate)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TaskEntity.dueDate, ascending: true)
        ]
        return request
    }

    /// Fetch request for completed tasks
    static func completedTasks() -> NSFetchRequest<TaskEntity> {
        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        request.predicate = NSPredicate(format: "isCompleted == YES")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TaskEntity.completedAt, ascending: false)
        ]
        return request
    }

    /// Fetch request for tasks with a specific tag
    static func tasks(withTag tag: TagEntity) -> NSFetchRequest<TaskEntity> {
        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        request.predicate = NSPredicate(format: "ANY tags == %@", tag)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TaskEntity.dueDate, ascending: true)
        ]
        return request
    }

    /// Fetch request for tasks with a specific priority
    static func tasks(withPriority priority: TaskPriority) -> NSFetchRequest<TaskEntity> {
        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        request.predicate = NSPredicate(format: "priority == %d", priority.rawValue)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TaskEntity.dueDate, ascending: true)
        ]
        return request
    }

    /// Fetch request for overdue tasks
    static func overdueTasks() -> NSFetchRequest<TaskEntity> {
        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        request.predicate = NSPredicate(format: "isCompleted == NO AND dueDate < %@", Date() as NSDate)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TaskEntity.dueDate, ascending: true)
        ]
        return request
    }

    /// Search tasks by title
    static func search(query: String) -> NSFetchRequest<TaskEntity> {
        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        request.predicate = NSPredicate(format: "title CONTAINS[cd] %@", query)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TaskEntity.dueDate, ascending: true)
        ]
        return request
    }
}
