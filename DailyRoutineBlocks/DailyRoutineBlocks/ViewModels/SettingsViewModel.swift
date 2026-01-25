//
//  SettingsViewModel.swift
//  DailyRoutineBlocks
//

import Foundation
import SwiftUI
import UserNotifications

@MainActor
class SettingsViewModel: ObservableObject {
    @AppStorage(UserDefaultsKeys.use24HourFormat) var use24HourFormat: Bool = false
    @AppStorage(UserDefaultsKeys.defaultReminderEnabled) var defaultReminderEnabled: Bool = false
    @AppStorage(UserDefaultsKeys.defaultReminderMinutes) var defaultReminderMinutes: Int = AppConstants.defaultReminderMinutes
    @AppStorage(UserDefaultsKeys.timelineStartHour) var timelineStartHour: Int = TimelineConstants.defaultStartHour
    @AppStorage(UserDefaultsKeys.timelineEndHour) var timelineEndHour: Int = TimelineConstants.defaultEndHour
    @AppStorage(UserDefaultsKeys.hasCompletedOnboarding) var hasCompletedOnboarding: Bool = false

    @Published var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined

    init() {
        Task {
            await checkNotificationPermissions()
        }
    }

    // MARK: - Notification Permissions

    func checkNotificationPermissions() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            notificationPermissionStatus = settings.authorizationStatus
        }
    }

    func requestNotificationPermissions() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            await checkNotificationPermissions()
            return granted
        } catch {
            print("Failed to request notification permissions: \(error)")
            return false
        }
    }

    // MARK: - Timeline Hours Validation

    var validStartHours: [Int] {
        Array(0..<timelineEndHour)
    }

    var validEndHours: [Int] {
        Array((timelineStartHour + 1)...24)
    }

    func validateTimelineHours() {
        if timelineStartHour >= timelineEndHour {
            timelineEndHour = min(timelineStartHour + 1, 24)
        }
    }

    // MARK: - Reminder Minutes Options

    var reminderMinutesOptions: [Int] {
        [5, 10, 15, 30, 45, 60]
    }

    // MARK: - Reset Settings

    func resetToDefaults() {
        use24HourFormat = false
        defaultReminderEnabled = false
        defaultReminderMinutes = AppConstants.defaultReminderMinutes
        timelineStartHour = TimelineConstants.defaultStartHour
        timelineEndHour = TimelineConstants.defaultEndHour
    }

    // MARK: - Format Helpers

    func formatHour(_ hour: Int) -> String {
        if use24HourFormat {
            return String(format: "%02d:00", hour)
        } else {
            if hour == 0 {
                return "12 AM"
            } else if hour < 12 {
                return "\(hour) AM"
            } else if hour == 12 {
                return "12 PM"
            } else {
                return "\(hour - 12) PM"
            }
        }
    }

    func formatReminderMinutes(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) minutes before"
        } else {
            let hours = minutes / 60
            return "\(hours) hour\(hours > 1 ? "s" : "") before"
        }
    }
}
