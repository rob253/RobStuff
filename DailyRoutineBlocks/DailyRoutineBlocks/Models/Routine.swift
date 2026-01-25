//
//  Routine.swift
//  DailyRoutineBlocks
//

import Foundation
import SwiftData

@Model
final class Routine {
    var id: UUID
    var name: String
    @Relationship(deleteRule: .cascade) var blocks: [RoutineBlock]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        blocks: [RoutineBlock] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.blocks = blocks
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var sortedBlocks: [RoutineBlock] {
        blocks.sorted { $0.startMinutesFromMidnight < $1.startMinutesFromMidnight }
    }

    var totalDuration: Int {
        blocks.reduce(0) { $0 + $1.durationMinutes }
    }

    var formattedTotalDuration: String {
        let hours = totalDuration / 60
        let minutes = totalDuration % 60
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    func applyToDate(_ date: Date) -> [TimeBlock] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        return blocks.map { routineBlock in
            let startTime = calendar.date(
                byAdding: .minute,
                value: routineBlock.startMinutesFromMidnight,
                to: startOfDay
            )!
            let endTime = calendar.date(
                byAdding: .minute,
                value: routineBlock.durationMinutes,
                to: startTime
            )!

            return TimeBlock(
                title: routineBlock.title,
                startTime: startTime,
                endTime: endTime,
                colorHex: routineBlock.colorHex,
                icon: routineBlock.icon,
                notes: routineBlock.notes
            )
        }
    }
}

extension Routine {
    static func sample() -> Routine {
        let routine = Routine(name: "Morning Routine")
        routine.blocks = [
            RoutineBlock(
                title: "Wake Up & Stretch",
                startMinutesFromMidnight: 6 * 60,
                durationMinutes: 30,
                colorHex: BlockColor.mint.hex,
                icon: "figure.cooldown"
            ),
            RoutineBlock(
                title: "Breakfast",
                startMinutesFromMidnight: 6 * 60 + 30,
                durationMinutes: 30,
                colorHex: BlockColor.orange.hex,
                icon: "fork.knife"
            ),
            RoutineBlock(
                title: "Exercise",
                startMinutesFromMidnight: 7 * 60,
                durationMinutes: 60,
                colorHex: BlockColor.red.hex,
                icon: "figure.run"
            )
        ]
        return routine
    }
}
