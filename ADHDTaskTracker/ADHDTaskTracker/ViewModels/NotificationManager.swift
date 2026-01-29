import Foundation
import UserNotifications
import UIKit

/// NotificationManager handles all push notification operations
/// including scheduling, canceling, and permission management
@MainActor
class NotificationManager: NSObject, ObservableObject {
    // MARK: - Singleton

    static let shared = NotificationManager()

    // MARK: - Published Properties

    /// Current authorization status
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    /// Whether notifications are fully enabled
    @Published var isAuthorized: Bool = false

    // MARK: - Properties

    private let notificationCenter = UNUserNotificationCenter.current()

    // MARK: - Initialization

    override init() {
        super.init()
        notificationCenter.delegate = self
        checkAuthorizationStatus()
    }

    // MARK: - Permission Handling

    /// Check current authorization status
    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            Task { @MainActor in
                self?.authorizationStatus = settings.authorizationStatus
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    /// Request notification permissions
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.isAuthorized = granted
                if granted {
                    self.authorizationStatus = .authorized
                }
            }
            return granted
        } catch {
            print("Failed to request notification authorization: \(error)")
            return false
        }
    }

    /// Open the app's notification settings in the Settings app
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Scheduling Notifications

    /// Schedule a notification for a task
    /// - Parameter task: The task to schedule a notification for
    func scheduleNotification(for task: TaskEntity) {
        guard task.notificationEnabled,
              let taskId = task.id,
              let dueDate = task.dueDate,
              let title = task.title else {
            return
        }

        // Calculate notification time
        let notificationMinutes = Int(task.notificationMinutesBefore)
        let notificationDate = dueDate.addingTimeInterval(-TimeInterval(notificationMinutes * 60))

        // Don't schedule if the notification time is in the past
        guard notificationDate > Date() else { return }

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = getNotificationTitle(for: task)
        content.body = title
        content.sound = .default
        content.badge = 1

        // Add category for actions
        content.categoryIdentifier = "TASK_REMINDER"

        // Add task info to userInfo for handling
        content.userInfo = [
            "taskId": taskId.uuidString,
            "taskTitle": title
        ]

        // Set priority-based interruption level (iOS 15+)
        if #available(iOS 15.0, *) {
            switch task.priority {
            case 2: // High
                content.interruptionLevel = .timeSensitive
            case 1: // Medium
                content.interruptionLevel = .active
            default: // Low
                content.interruptionLevel = .passive
            }
        }

        // Create trigger
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        // Create request
        let identifier = notificationIdentifier(for: task)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        // Schedule the notification
        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    /// Get appropriate notification title based on timing
    private func getNotificationTitle(for task: TaskEntity) -> String {
        let minutes = Int(task.notificationMinutesBefore)

        switch minutes {
        case 0:
            return "Task Due Now"
        case 15:
            return "Task Due in 15 Minutes"
        case 30:
            return "Task Due in 30 Minutes"
        case 60:
            return "Task Due in 1 Hour"
        case 120:
            return "Task Due in 2 Hours"
        case 1440:
            return "Task Due Tomorrow"
        default:
            if minutes < 60 {
                return "Task Due in \(minutes) Minutes"
            } else {
                let hours = minutes / 60
                return "Task Due in \(hours) Hour\(hours == 1 ? "" : "s")"
            }
        }
    }

    /// Cancel a scheduled notification for a task
    /// - Parameter task: The task whose notification should be canceled
    func cancelNotification(for task: TaskEntity) {
        let identifier = notificationIdentifier(for: task)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Cancel all pending notifications
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    /// Get all pending notifications
    func getPendingNotifications() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }

    // MARK: - Helper Methods

    /// Generate a unique notification identifier for a task
    private func notificationIdentifier(for task: TaskEntity) -> String {
        guard let id = task.id else { return UUID().uuidString }
        return "task_\(id.uuidString)"
    }

    // MARK: - Notification Categories

    /// Register notification categories and actions
    func registerCategories() {
        // "Mark Complete" action
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_ACTION",
            title: "Mark Complete",
            options: []
        )

        // "Snooze" action (delay 15 minutes)
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Snooze 15 min",
            options: []
        )

        // "View" action (opens app)
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACTION",
            title: "View Task",
            options: .foreground
        )

        // Create category
        let category = UNNotificationCategory(
            identifier: "TASK_REMINDER",
            actions: [completeAction, snoozeAction, viewAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        notificationCenter.setNotificationCategories([category])
    }

    // MARK: - Badge Management

    /// Update the app badge count
    func updateBadgeCount(to count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count)
    }

    /// Clear the app badge
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    /// Handle notification when app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    /// Handle notification action (when user taps notification or action button)
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        switch response.actionIdentifier {
        case "COMPLETE_ACTION":
            // Handle mark complete action
            if let taskIdString = userInfo["taskId"] as? String,
               let taskId = UUID(uuidString: taskIdString) {
                Task { @MainActor in
                    NotificationCenter.default.post(
                        name: .taskCompletedFromNotification,
                        object: nil,
                        userInfo: ["taskId": taskId]
                    )
                }
            }

        case "SNOOZE_ACTION":
            // Reschedule notification for 15 minutes later
            if let taskIdString = userInfo["taskId"] as? String,
               let taskTitle = userInfo["taskTitle"] as? String {
                Task { @MainActor in
                    self.scheduleSnoozeNotification(taskId: taskIdString, title: taskTitle)
                }
            }

        case "VIEW_ACTION", UNNotificationDefaultActionIdentifier:
            // Open the task in the app
            if let taskIdString = userInfo["taskId"] as? String,
               let taskId = UUID(uuidString: taskIdString) {
                Task { @MainActor in
                    NotificationCenter.default.post(
                        name: .openTaskFromNotification,
                        object: nil,
                        userInfo: ["taskId": taskId]
                    )
                }
            }

        default:
            break
        }

        completionHandler()
    }

    /// Schedule a snooze notification (15 minutes from now)
    private func scheduleSnoozeNotification(taskId: String, title: String) {
        let content = UNMutableNotificationContent()
        content.title = "Snoozed Reminder"
        content.body = title
        content.sound = .default
        content.categoryIdentifier = "TASK_REMINDER"
        content.userInfo = [
            "taskId": taskId,
            "taskTitle": title
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 15 * 60, repeats: false)
        let identifier = "snooze_\(taskId)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when a task is marked complete from a notification action
    static let taskCompletedFromNotification = Notification.Name("taskCompletedFromNotification")

    /// Posted when user taps a notification to open a specific task
    static let openTaskFromNotification = Notification.Name("openTaskFromNotification")
}
