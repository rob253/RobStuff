//
//  TimeBlock.swift
//  DailyRoutineBlocks
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class TimeBlock {
    var id: UUID
    var title: String
    var startTime: Date
    var endTime: Date
    var colorHex: String
    var icon: String?
    var notes: String?
    var isCompleted: Bool
    var notificationEnabled: Bool
    var reminderMinutesBefore: Int?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        startTime: Date,
        endTime: Date,
        colorHex: String = BlockColor.blue.hex,
        icon: String? = nil,
        notes: String? = nil,
        isCompleted: Bool = false,
        notificationEnabled: Bool = false,
        reminderMinutesBefore: Int? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.colorHex = colorHex
        self.icon = icon
        self.notes = notes
        self.isCompleted = isCompleted
        self.notificationEnabled = notificationEnabled
        self.reminderMinutesBefore = reminderMinutesBefore
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var color: Color {
        Color(hex: colorHex) ?? .blue
    }

    var durationMinutes: Int {
        Calendar.current.dateComponents([.minute], from: startTime, to: endTime).minute ?? 0
    }

    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }

    var formattedDuration: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    func update(
        title: String? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil,
        colorHex: String? = nil,
        icon: String? = nil,
        notes: String? = nil,
        isCompleted: Bool? = nil,
        notificationEnabled: Bool? = nil,
        reminderMinutesBefore: Int? = nil
    ) {
        if let title = title { self.title = title }
        if let startTime = startTime { self.startTime = startTime }
        if let endTime = endTime { self.endTime = endTime }
        if let colorHex = colorHex { self.colorHex = colorHex }
        if let icon = icon { self.icon = icon }
        if let notes = notes { self.notes = notes }
        if let isCompleted = isCompleted { self.isCompleted = isCompleted }
        if let notificationEnabled = notificationEnabled { self.notificationEnabled = notificationEnabled }
        if let reminderMinutesBefore = reminderMinutesBefore { self.reminderMinutesBefore = reminderMinutesBefore }
        self.updatedAt = Date()
    }
}

extension TimeBlock {
    static func sample(
        title: String = "Sample Block",
        startTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!,
        endTime: Date = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date())!,
        colorHex: String = BlockColor.blue.hex
    ) -> TimeBlock {
        TimeBlock(
            title: title,
            startTime: startTime,
            endTime: endTime,
            colorHex: colorHex
        )
    }
}
