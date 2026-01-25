//
//  DataService.swift
//  DailyRoutineBlocks
//

import Foundation
import SwiftData

@MainActor
class DataService {
    static let shared = DataService()

    private init() {}

    // MARK: - Sample Data

    func createSampleData(in context: ModelContext) {
        // Check if data already exists
        let descriptor = FetchDescriptor<TimeBlock>()
        let existingBlocks = (try? context.fetch(descriptor)) ?? []

        guard existingBlocks.isEmpty else { return }

        let today = Date()
        let calendar = Calendar.current

        // Create sample time blocks for today
        let sampleBlocks: [(String, Int, Int, BlockColor, String?)] = [
            ("Morning Routine", 6, 7, .mint, "figure.cooldown"),
            ("Breakfast", 7, 8, .orange, "fork.knife"),
            ("Deep Work", 8, 11, .blue, "laptopcomputer"),
            ("Team Standup", 11, 12, .indigo, "video"),
            ("Lunch Break", 12, 13, .yellow, "takeoutbag.and.cup.and.straw"),
            ("Meetings", 13, 15, .purple, "person.2"),
            ("Focus Time", 15, 17, .teal, "brain.head.profile"),
            ("Exercise", 17, 18, .red, "figure.run"),
            ("Dinner", 18, 19, .orange, "fork.knife"),
            ("Reading", 20, 21, .green, "book"),
            ("Wind Down", 21, 22, .pink, "moon.stars")
        ]

        for (title, startHour, endHour, color, icon) in sampleBlocks {
            let startTime = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: today)!
            let endTime = calendar.date(bySettingHour: endHour, minute: 0, second: 0, of: today)!

            let block = TimeBlock(
                title: title,
                startTime: startTime,
                endTime: endTime,
                colorHex: color.hex,
                icon: icon
            )
            context.insert(block)
        }

        // Create sample routines
        createSampleRoutines(in: context)

        try? context.save()
    }

    private func createSampleRoutines(in context: ModelContext) {
        // Morning Routine
        let morningRoutine = Routine(name: "Morning Routine")
        morningRoutine.blocks = [
            RoutineBlock(
                title: "Wake Up & Stretch",
                startMinutesFromMidnight: 6 * 60,
                durationMinutes: 30,
                colorHex: BlockColor.mint.hex,
                icon: "figure.cooldown"
            ),
            RoutineBlock(
                title: "Meditation",
                startMinutesFromMidnight: 6 * 60 + 30,
                durationMinutes: 15,
                colorHex: BlockColor.purple.hex,
                icon: "brain.head.profile"
            ),
            RoutineBlock(
                title: "Breakfast",
                startMinutesFromMidnight: 6 * 60 + 45,
                durationMinutes: 30,
                colorHex: BlockColor.orange.hex,
                icon: "fork.knife"
            ),
            RoutineBlock(
                title: "Get Ready",
                startMinutesFromMidnight: 7 * 60 + 15,
                durationMinutes: 45,
                colorHex: BlockColor.teal.hex,
                icon: "sparkles"
            )
        ]
        context.insert(morningRoutine)

        // Work Day Routine
        let workDayRoutine = Routine(name: "Work Day")
        workDayRoutine.blocks = [
            RoutineBlock(
                title: "Check Emails",
                startMinutesFromMidnight: 9 * 60,
                durationMinutes: 30,
                colorHex: BlockColor.blue.hex,
                icon: "envelope"
            ),
            RoutineBlock(
                title: "Deep Work",
                startMinutesFromMidnight: 9 * 60 + 30,
                durationMinutes: 120,
                colorHex: BlockColor.indigo.hex,
                icon: "laptopcomputer"
            ),
            RoutineBlock(
                title: "Team Standup",
                startMinutesFromMidnight: 11 * 60 + 30,
                durationMinutes: 30,
                colorHex: BlockColor.purple.hex,
                icon: "video"
            ),
            RoutineBlock(
                title: "Lunch",
                startMinutesFromMidnight: 12 * 60,
                durationMinutes: 60,
                colorHex: BlockColor.orange.hex,
                icon: "fork.knife"
            ),
            RoutineBlock(
                title: "Meetings",
                startMinutesFromMidnight: 13 * 60,
                durationMinutes: 120,
                colorHex: BlockColor.teal.hex,
                icon: "person.2"
            ),
            RoutineBlock(
                title: "Focus Time",
                startMinutesFromMidnight: 15 * 60,
                durationMinutes: 120,
                colorHex: BlockColor.green.hex,
                icon: "brain.head.profile"
            )
        ]
        context.insert(workDayRoutine)

        // Evening Routine
        let eveningRoutine = Routine(name: "Evening Routine")
        eveningRoutine.blocks = [
            RoutineBlock(
                title: "Exercise",
                startMinutesFromMidnight: 17 * 60,
                durationMinutes: 60,
                colorHex: BlockColor.red.hex,
                icon: "figure.run"
            ),
            RoutineBlock(
                title: "Dinner",
                startMinutesFromMidnight: 18 * 60 + 30,
                durationMinutes: 45,
                colorHex: BlockColor.orange.hex,
                icon: "fork.knife"
            ),
            RoutineBlock(
                title: "Family Time",
                startMinutesFromMidnight: 19 * 60 + 15,
                durationMinutes: 90,
                colorHex: BlockColor.pink.hex,
                icon: "person.2"
            ),
            RoutineBlock(
                title: "Reading",
                startMinutesFromMidnight: 20 * 60 + 45,
                durationMinutes: 45,
                colorHex: BlockColor.green.hex,
                icon: "book"
            ),
            RoutineBlock(
                title: "Wind Down",
                startMinutesFromMidnight: 21 * 60 + 30,
                durationMinutes: 30,
                colorHex: BlockColor.purple.hex,
                icon: "moon.stars"
            )
        ]
        context.insert(eveningRoutine)
    }

    // MARK: - Data Queries

    func fetchBlocks(for date: Date, in context: ModelContext) -> [TimeBlock] {
        let startOfDay = date.startOfDay
        let endOfDay = date.endOfDay

        let predicate = #Predicate<TimeBlock> { block in
            block.startTime >= startOfDay && block.startTime <= endOfDay
        }

        var descriptor = FetchDescriptor<TimeBlock>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\.startTime)]

        return (try? context.fetch(descriptor)) ?? []
    }

    func fetchAllRoutines(in context: ModelContext) -> [Routine] {
        var descriptor = FetchDescriptor<Routine>()
        descriptor.sortBy = [SortDescriptor(\.name)]

        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Data Management

    func deleteAllBlocks(in context: ModelContext) {
        let descriptor = FetchDescriptor<TimeBlock>()
        if let blocks = try? context.fetch(descriptor) {
            for block in blocks {
                context.delete(block)
            }
            try? context.save()
        }
    }

    func deleteAllRoutines(in context: ModelContext) {
        let descriptor = FetchDescriptor<Routine>()
        if let routines = try? context.fetch(descriptor) {
            for routine in routines {
                context.delete(routine)
            }
            try? context.save()
        }
    }

    func deleteAllData(in context: ModelContext) {
        deleteAllBlocks(in: context)
        deleteAllRoutines(in: context)
    }

    // MARK: - Statistics

    func calculateTotalTime(for blocks: [TimeBlock]) -> Int {
        blocks.reduce(0) { $0 + $1.durationMinutes }
    }

    func calculateCompletedTime(for blocks: [TimeBlock]) -> Int {
        blocks.filter(\.isCompleted).reduce(0) { $0 + $1.durationMinutes }
    }

    func completionRate(for blocks: [TimeBlock]) -> Double {
        guard !blocks.isEmpty else { return 0 }
        let completed = blocks.filter(\.isCompleted).count
        return Double(completed) / Double(blocks.count)
    }

    func timeByColor(for blocks: [TimeBlock]) -> [String: Int] {
        var result: [String: Int] = [:]
        for block in blocks {
            result[block.colorHex, default: 0] += block.durationMinutes
        }
        return result
    }
}
