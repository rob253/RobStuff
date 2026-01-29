import SwiftUI
import CoreData

/// Main entry point for the ADHD Task Tracker app
@main
struct ADHDTaskTrackerApp: App {
    // MARK: - Core Data

    let persistenceController = PersistenceController.shared

    // MARK: - State

    @StateObject private var taskViewModel: TaskViewModel
    @StateObject private var tagViewModel: TagViewModel
    @StateObject private var analyticsViewModel: AnalyticsViewModel
    @StateObject private var notificationManager = NotificationManager.shared

    // MARK: - Environment

    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Initialization

    init() {
        let context = PersistenceController.shared.container.viewContext
        _taskViewModel = StateObject(wrappedValue: TaskViewModel(context: context))
        _tagViewModel = StateObject(wrappedValue: TagViewModel(context: context))
        _analyticsViewModel = StateObject(wrappedValue: AnalyticsViewModel(context: context))

        // Configure appearance
        configureAppearance()
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(taskViewModel)
                .environmentObject(tagViewModel)
                .environmentObject(analyticsViewModel)
                .environmentObject(notificationManager)
                .onAppear {
                    setupNotifications()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    handleScenePhaseChange(newPhase)
                }
                .onReceive(NotificationCenter.default.publisher(for: .taskCompletedFromNotification)) { notification in
                    handleTaskCompletedNotification(notification)
                }
                .onReceive(NotificationCenter.default.publisher(for: .openTaskFromNotification)) { notification in
                    handleOpenTaskNotification(notification)
                }
        }
    }

    // MARK: - Setup

    /// Configure global appearance settings
    private func configureAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance

        // Configure tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()

        UITabBar.appearance().standardAppearance = tabAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        }
    }

    /// Setup notification permissions and categories
    private func setupNotifications() {
        notificationManager.registerCategories()

        Task {
            let _ = await notificationManager.requestAuthorization()
        }
    }

    // MARK: - Scene Phase Handling

    /// Handle app lifecycle changes
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // Clear badge when app becomes active
            notificationManager.clearBadge()
            // Refresh data
            taskViewModel.fetchTasks()
            analyticsViewModel.refreshAnalytics()

        case .background:
            // Save any pending changes
            persistenceController.save()
            // Update badge with overdue task count
            notificationManager.updateBadgeCount(to: taskViewModel.overdueTasks)

        case .inactive:
            break

        @unknown default:
            break
        }
    }

    // MARK: - Notification Handling

    /// Handle task completed from notification action
    private func handleTaskCompletedNotification(_ notification: Notification) {
        guard let taskId = notification.userInfo?["taskId"] as? UUID else { return }

        // Find and complete the task
        if let task = taskViewModel.allTasks.first(where: { $0.id == taskId }) {
            taskViewModel.toggleCompletion(for: task)
        }
    }

    /// Handle opening a task from notification tap
    private func handleOpenTaskNotification(_ notification: Notification) {
        // The task detail view navigation will be handled by ContentView
        // through a published property or navigation state
        guard let _ = notification.userInfo?["taskId"] as? UUID else { return }

        // TODO: Navigate to task detail
        // This would typically update a @Published state that ContentView observes
    }
}
