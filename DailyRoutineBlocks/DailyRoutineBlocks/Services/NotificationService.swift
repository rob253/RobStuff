//
//  NotificationService.swift
//  DailyRoutineBlocks
//

import Foundation
import UserNotifications

@MainActor
class NotificationService {
    static let shared = NotificationService()

    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }

    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Schedule Notifications

    func scheduleNotification(for block: TimeBlock) async {
        guard block.notificationEnabled,
              let minutesBefore = block.reminderMinutesBefore else {
            return
        }

        // Remove any existing notification for this block
        await removeNotification(for: block)

        // Calculate notification time
        let notificationTime = block.startTime.adding(minutes: -minutesBefore)

        // Don't schedule if the notification time has passed
        guard notificationTime > Date() else { return }

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Upcoming: \(block.title)"
        content.body = "Starting in \(minutesBefore) minutes at \(block.startTime.formattedTime())"
        content.sound = .default
        content.categoryIdentifier = "BLOCK_REMINDER"

        // Add block info to userInfo for handling taps
        content.userInfo = [
            "blockId": block.id.uuidString,
            "blockTitle": block.title
        ]

        // Create trigger
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: notificationTime
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        // Create request
        let request = UNNotificationRequest(
            identifier: notificationIdentifier(for: block),
            content: content,
            trigger: trigger
        )

        // Schedule
        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }

    func removeNotification(for block: TimeBlock) async {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [notificationIdentifier(for: block)]
        )
    }

    func removeAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    // MARK: - Batch Operations

    func scheduleNotifications(for blocks: [TimeBlock]) async {
        for block in blocks {
            await scheduleNotification(for: block)
        }
    }

    func updateNotifications(for blocks: [TimeBlock]) async {
        // Remove all existing notifications
        let identifiers = blocks.map { notificationIdentifier(for: $0) }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)

        // Re-schedule enabled notifications
        for block in blocks where block.notificationEnabled {
            await scheduleNotification(for: block)
        }
    }

    // MARK: - Helpers

    private func notificationIdentifier(for block: TimeBlock) -> String {
        "block-\(block.id.uuidString)"
    }

    // MARK: - Notification Categories

    func setupNotificationCategories() {
        // Define actions
        let markCompleteAction = UNNotificationAction(
            identifier: "MARK_COMPLETE",
            title: "Mark Complete",
            options: []
        )

        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE",
            title: "Snooze 5 min",
            options: []
        )

        // Define category
        let blockReminderCategory = UNNotificationCategory(
            identifier: "BLOCK_REMINDER",
            actions: [markCompleteAction, snoozeAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        notificationCenter.setNotificationCategories([blockReminderCategory])
    }

    // MARK: - Pending Notifications

    func getPendingNotifications() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }

    func getDeliveredNotifications() async -> [UNNotification] {
        await notificationCenter.deliveredNotifications()
    }
}

// MARK: - Notification Delegate Handler

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    private override init() {
        super.init()
    }

    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .badge]
    }

    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo

        guard let blockIdString = userInfo["blockId"] as? String,
              let _ = UUID(uuidString: blockIdString) else {
            return
        }

        switch response.actionIdentifier {
        case "MARK_COMPLETE":
            // Handle mark complete action
            // This would need to communicate with the app to update the block
            NotificationCenter.default.post(
                name: .blockMarkedCompleteFromNotification,
                object: nil,
                userInfo: userInfo
            )

        case "SNOOZE":
            // Handle snooze action
            // Schedule a new notification for 5 minutes from now
            await scheduleSnoozeNotification(for: userInfo)

        default:
            // Default tap - open the block detail
            NotificationCenter.default.post(
                name: .blockNotificationTapped,
                object: nil,
                userInfo: userInfo
            )
        }
    }

    private func scheduleSnoozeNotification(for userInfo: [AnyHashable: Any]) async {
        guard let blockIdString = userInfo["blockId"] as? String,
              let blockTitle = userInfo["blockTitle"] as? String else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Reminder: \(blockTitle)"
        content.body = "Snoozed reminder"
        content.sound = .default
        content.userInfo = userInfo

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 300, repeats: false) // 5 minutes

        let request = UNNotificationRequest(
            identifier: "snooze-\(blockIdString)",
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let blockMarkedCompleteFromNotification = Notification.Name("blockMarkedCompleteFromNotification")
    static let blockNotificationTapped = Notification.Name("blockNotificationTapped")
}
