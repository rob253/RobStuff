import CoreData

/// PersistenceController manages the Core Data stack for the app.
/// It provides a shared instance for production use and a preview instance for SwiftUI previews.
struct PersistenceController {
    // MARK: - Shared Instance

    /// The shared persistence controller used throughout the app
    static let shared = PersistenceController()

    /// Preview instance with sample data for SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        // Create sample tags
        let workTag = TagEntity(context: context)
        workTag.id = UUID()
        workTag.name = "Work"
        workTag.colorHex = "#6B9AC4"
        workTag.createdAt = Date()

        let personalTag = TagEntity(context: context)
        personalTag.id = UUID()
        personalTag.name = "Personal"
        personalTag.colorHex = "#B2C9AB"
        personalTag.createdAt = Date()

        let healthTag = TagEntity(context: context)
        healthTag.id = UUID()
        healthTag.name = "Health"
        healthTag.colorHex = "#7FB3A5"
        healthTag.createdAt = Date()

        // Create sample tasks
        let task1 = TaskEntity(context: context)
        task1.id = UUID()
        task1.title = "Complete project report"
        task1.taskDescription = "Finish the quarterly report and send to team"
        task1.dueDate = Date().addingTimeInterval(3600 * 2) // 2 hours from now
        task1.createdAt = Date()
        task1.priority = 2 // High
        task1.isCompleted = false
        task1.notificationEnabled = true
        task1.notificationMinutesBefore = 30
        task1.tags = NSSet(array: [workTag])

        let task2 = TaskEntity(context: context)
        task2.id = UUID()
        task2.title = "Go for a walk"
        task2.taskDescription = "Take a 30-minute walk in the park"
        task2.dueDate = Date().addingTimeInterval(3600 * 5) // 5 hours from now
        task2.createdAt = Date()
        task2.priority = 1 // Medium
        task2.isCompleted = false
        task2.notificationEnabled = true
        task2.notificationMinutesBefore = 15
        task2.tags = NSSet(array: [healthTag, personalTag])

        let task3 = TaskEntity(context: context)
        task3.id = UUID()
        task3.title = "Buy groceries"
        task3.dueDate = Date().addingTimeInterval(3600 * 24) // Tomorrow
        task3.createdAt = Date()
        task3.priority = 0 // Low
        task3.isCompleted = true
        task3.completedAt = Date()
        task3.notificationEnabled = false
        task3.tags = NSSet(array: [personalTag])

        // Create a recurring task
        let task4 = TaskEntity(context: context)
        task4.id = UUID()
        task4.title = "Daily meditation"
        task4.taskDescription = "10 minutes of mindfulness"
        task4.dueDate = Calendar.current.startOfDay(for: Date()).addingTimeInterval(3600 * 7) // 7 AM
        task4.createdAt = Date()
        task4.priority = 1
        task4.isCompleted = false
        task4.isRecurring = true
        task4.recurringPattern = "daily"
        task4.recurringInterval = 1
        task4.notificationEnabled = true
        task4.notificationMinutesBefore = 15
        task4.tags = NSSet(array: [healthTag])

        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }

        return controller
    }()

    // MARK: - Properties

    /// The persistent container that manages the Core Data stack
    let container: NSPersistentContainer

    // MARK: - Initialization

    /// Initializes the persistence controller
    /// - Parameter inMemory: If true, uses an in-memory store (useful for previews and testing)
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ADHDTaskTracker")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // In production, handle this error gracefully instead of crashing
                fatalError("Core Data store failed to load: \(error), \(error.userInfo)")
            }
        }

        // Configure automatic merging of changes from parent contexts
        container.viewContext.automaticallyMergesChangesFromParent = true

        // Set merge policy to handle conflicts (prefer in-memory changes)
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Save Context

    /// Saves the view context if there are any changes
    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                // In production, handle this error gracefully
                print("Error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
