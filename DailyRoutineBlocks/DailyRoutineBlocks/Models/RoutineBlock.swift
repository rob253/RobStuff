//
//  RoutineBlock.swift
//  DailyRoutineBlocks
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class RoutineBlock {
    var id: UUID
    var title: String
    var startMinutesFromMidnight: Int
    var durationMinutes: Int
    var colorHex: String
    var icon: String?
    var notes: String?

    @Relationship(inverse: \Routine.blocks) var routine: Routine?

    init(
        id: UUID = UUID(),
        title: String,
        startMinutesFromMidnight: Int,
        durationMinutes: Int,
        colorHex: String = BlockColor.blue.hex,
        icon: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.title = title
        self.startMinutesFromMidnight = startMinutesFromMidnight
        self.durationMinutes = durationMinutes
        self.colorHex = colorHex
        self.icon = icon
        self.notes = notes
    }

    var color: Color {
        Color(hex: colorHex) ?? .blue
    }

    var endMinutesFromMidnight: Int {
        startMinutesFromMidnight + durationMinutes
    }

    var formattedStartTime: String {
        let hours = startMinutesFromMidnight / 60
        let minutes = startMinutesFromMidnight % 60
        let period = hours < 12 ? "AM" : "PM"
        let displayHour = hours == 0 ? 12 : (hours > 12 ? hours - 12 : hours)
        return String(format: "%d:%02d %@", displayHour, minutes, period)
    }

    var formattedEndTime: String {
        let totalMinutes = endMinutesFromMidnight
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        let period = hours < 12 ? "AM" : "PM"
        let displayHour = hours == 0 ? 12 : (hours > 12 ? hours - 12 : hours)
        return String(format: "%d:%02d %@", displayHour, minutes, period)
    }

    var formattedTimeRange: String {
        "\(formattedStartTime) - \(formattedEndTime)"
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
}
