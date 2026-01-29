import Foundation
import CoreData
import SwiftUI
import Combine

/// TaskViewModel manages task-related operations and state
/// It provides filtering, sorting, and CRUD operations for tasks
@MainActor
class TaskViewModel: ObservableObject {
    // MARK: - Published Properties

    /// All tasks from Core Data
    @Published var allTasks: [TaskEntity] = []

    /// Currently displayed tasks (after filtering and sorting)
    @Published var displayedTasks: [TaskEntity] = []

    /// Current filter settings
    @Published var currentFilter: TaskFilter = .all {
        didSet { applyFiltersAndSort() }
    }

    /// Current sort option
    @Published var currentSort: TaskSort = .dueDate {
        didSet { applyFiltersAndSort() }
    }

    /// Selected tags for filtering (empty means no tag filter)
    @Published var selectedTags: Set<TagEntity> = [] {
        didSet { applyFiltersAndSort() }
    }

    /// Selected priority for filtering (nil means no priority filter)
    @Published var selectedPriority: TaskPriority? = nil {
        didSet { applyFiltersAndSort() }
    }

    /// Search query
    @Published var searchQuery: String = "" {
        didSet { applyFiltersAndSort() }
    }

    /// Tasks grouped by date (for calendar view)
    @Published var tasksByDate: [Date: [TaskEntity]] = [:]

    /// Current week being viewed
    @Published var currentWeek: Date = Date()

    /// Loading state
    @Published var isLoading: Bool = false

    /// Error message for display
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let viewContext: NSManagedObjectContext
    private let notificationManager: NotificationManager

    // MARK: - Initialization

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext,
         notificationManager: NotificationManager = NotificationManager.shared) {
        self.viewContext = context
        self.notificationManager = notificationManager
        fetchTasks()
    }

    // MARK: - Fetch Tasks

    /// Fetch all tasks from Core Data
    func fetchTasks() {
        isLoading = true

        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.dueDate, ascending: true)]

        do {
            allTasks = try viewContext.fetch(request)
            applyFiltersAndSort()
            updateTasksByDate()
            isLoading = false
        } catch {
            errorMessage = "Failed to fetch tasks: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Filter and Sort

    /// Apply current filters and sort to the tasks
    private func applyFiltersAndSort() {
        var filtered = allTasks

        // Apply main filter
        switch currentFilter {
        case .all:
            break
        case .today:
            filtered = filtered.filter { $0.isDueToday }
        case .thisWeek:
            filtered = filtered.filter { $0.isDueThisWeek }
        case .incomplete:
            filtered = filtered.filter { !$0.isCompleted }
        case .completed:
            filtered = filtered.filter { $0.isCompleted }
        case .overdue:
            filtered = filtered.filter { $0.status == .overdue }
        }

        // Apply tag filter
        if !selectedTags.isEmpty {
            filtered = filtered.filter { task in
                let taskTags = Set(task.tagsArray)
                return !taskTags.isDisjoint(with: selectedTags)
            }
        }

        // Apply priority filter
        if let priority = selectedPriority {
            filtered = filtered.filter { $0.priority == priority.rawValue }
        }

        // Apply search filter
        if !searchQuery.isEmpty {
            filtered = filtered.filter { task in
                task.title?.localizedCaseInsensitiveContains(searchQuery) ?? false ||
                task.taskDescription?.localizedCaseInsensitiveContains(searchQuery) ?? false
            }
        }

        // Apply sort
        switch currentSort {
        case .dueDate:
            filtered.sort { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        case .priority:
            filtered.sort { $0.priority > $1.priority }
        case .createdAt:
            filtered.sort { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
        case .title:
            filtered.sort { ($0.title ?? "") < ($1.title ?? "") }
        }

        displayedTasks = filtered
    }

    /// Update the tasks grouped by date for calendar view
    private func updateTasksByDate() {
        var grouped: [Date: [TaskEntity]] = [:]

        for task in allTasks {
            guard let dueDate = task.dueDate else { continue }
            let dayStart = dueDate.startOfDay
            if grouped[dayStart] == nil {
                grouped[dayStart] = []
            }
            grouped[dayStart]?.append(task)
        }

        // Sort tasks within each day
        for (date, tasks) in grouped {
            grouped[date] = tasks.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        }

        tasksByDate = grouped
    }

    // MARK: - CRUD Operations

    /// Create a new task
    func createTask(
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
    ) {
        let task = TaskEntity.create(
            in: viewContext,
            title: title,
            description: description,
            dueDate: dueDate,
            priority: priority,
            tags: tags,
            notificationEnabled: notificationEnabled,
            notificationMinutesBefore: notificationMinutesBefore,
            isRecurring: isRecurring,
            recurringPattern: recurringPattern,
            recurringInterval: recurringInterval,
            recurringEndDate: recurringEndDate
        )

        saveContext()

        // Schedule notification if enabled
        if notificationEnabled {
            notificationManager.scheduleNotification(for: task)
        }

        fetchTasks()
    }

    /// Update an existing task
    func updateTask(
        _ task: TaskEntity,
        title: String? = nil,
        description: String? = nil,
        dueDate: Date? = nil,
        priority: TaskPriority? = nil,
        tags: [TagEntity]? = nil,
        notificationEnabled: Bool? = nil,
        notificationMinutesBefore: Int32? = nil,
        isRecurring: Bool? = nil,
        recurringPattern: String? = nil,
        recurringInterval: Int32? = nil,
        recurringEndDate: Date? = nil
    ) {
        if let title = title { task.title = title }
        if let description = description { task.taskDescription = description }
        if let dueDate = dueDate { task.dueDate = dueDate }
        if let priority = priority { task.priority = priority.rawValue }
        if let tags = tags { task.tags = NSSet(array: tags) }
        if let notificationEnabled = notificationEnabled { task.notificationEnabled = notificationEnabled }
        if let notificationMinutesBefore = notificationMinutesBefore { task.notificationMinutesBefore = notificationMinutesBefore }
        if let isRecurring = isRecurring { task.isRecurring = isRecurring }
        if let recurringPattern = recurringPattern { task.recurringPattern = recurringPattern }
        if let recurringInterval = recurringInterval { task.recurringInterval = recurringInterval }
        if let recurringEndDate = recurringEndDate { task.recurringEndDate = recurringEndDate }

        saveContext()

        // Update notification
        notificationManager.cancelNotification(for: task)
        if task.notificationEnabled {
            notificationManager.scheduleNotification(for: task)
        }

        fetchTasks()
    }

    /// Delete a task
    func deleteTask(_ task: TaskEntity) {
        // Cancel any pending notifications
        notificationManager.cancelNotification(for: task)

        viewContext.delete(task)
        saveContext()
        fetchTasks()
    }

    /// Delete multiple tasks
    func deleteTasks(_ tasks: [TaskEntity]) {
        for task in tasks {
            notificationManager.cancelNotification(for: task)
            viewContext.delete(task)
        }
        saveContext()
        fetchTasks()
    }

    /// Toggle task completion
    func toggleCompletion(for task: TaskEntity) {
        let nextTask = task.toggleCompletion(in: viewContext)
        saveContext()

        // Schedule notification for next recurring task if created
        if let nextTask = nextTask, nextTask.notificationEnabled {
            notificationManager.scheduleNotification(for: nextTask)
        }

        fetchTasks()
    }

    // MARK: - Helper Methods

    /// Save the view context
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }

    /// Get tasks for a specific date
    func tasks(for date: Date) -> [TaskEntity] {
        let dayStart = date.startOfDay
        return tasksByDate[dayStart] ?? []
    }

    /// Get tasks for the current week
    func tasksForCurrentWeek() -> [TaskEntity] {
        let startOfWeek = currentWeek.startOfWeek
        let endOfWeek = currentWeek.endOfWeek

        return allTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate >= startOfWeek && dueDate <= endOfWeek
        }.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    /// Navigate to previous week
    func previousWeek() {
        if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentWeek) {
            currentWeek = newDate
        }
    }

    /// Navigate to next week
    func nextWeek() {
        if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentWeek) {
            currentWeek = newDate
        }
    }

    /// Reset to current week
    func goToThisWeek() {
        currentWeek = Date()
    }

    /// Clear all filters
    func clearFilters() {
        currentFilter = .all
        selectedTags = []
        selectedPriority = nil
        searchQuery = ""
    }

    // MARK: - Statistics

    /// Number of tasks completed today
    var tasksCompletedToday: Int {
        allTasks.filter { task in
            guard task.isCompleted, let completedAt = task.completedAt else { return false }
            return completedAt.isToday
        }.count
    }

    /// Number of tasks due today
    var tasksDueToday: Int {
        allTasks.filter { $0.isDueToday && !$0.isCompleted }.count
    }

    /// Number of overdue tasks
    var overdueTasks: Int {
        allTasks.filter { $0.status == .overdue }.count
    }
}

// MARK: - Filter and Sort Enums

/// Available task filters
enum TaskFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case today = "Today"
    case thisWeek = "This Week"
    case incomplete = "Incomplete"
    case completed = "Completed"
    case overdue = "Overdue"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: return "tray.full"
        case .today: return "sun.max"
        case .thisWeek: return "calendar"
        case .incomplete: return "circle"
        case .completed: return "checkmark.circle"
        case .overdue: return "exclamationmark.circle"
        }
    }
}

/// Available sort options
enum TaskSort: String, CaseIterable, Identifiable {
    case dueDate = "Due Date"
    case priority = "Priority"
    case createdAt = "Created"
    case title = "Title"

    var id: String { rawValue }
}
