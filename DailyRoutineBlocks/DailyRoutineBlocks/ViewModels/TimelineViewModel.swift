//
//  TimelineViewModel.swift
//  DailyRoutineBlocks
//

import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
class TimelineViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var selectedBlock: TimeBlock?
    @Published var isShowingBlockCreation: Bool = false
    @Published var isShowingBlockDetail: Bool = false
    @Published var newBlockStartTime: Date = Date()
    @Published var isEditMode: Bool = false
    @Published var draggedBlock: TimeBlock?

    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()

    // Settings
    @AppStorage(UserDefaultsKeys.use24HourFormat) var use24HourFormat: Bool = false
    @AppStorage(UserDefaultsKeys.timelineStartHour) var startHour: Int = TimelineConstants.defaultStartHour
    @AppStorage(UserDefaultsKeys.timelineEndHour) var endHour: Int = TimelineConstants.defaultEndHour

    init() {
        setupCurrentTimeUpdates()
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Date Navigation

    func goToToday() {
        selectedDate = Date()
    }

    func goToPreviousDay() {
        selectedDate = selectedDate.adding(days: -1)
    }

    func goToNextDay() {
        selectedDate = selectedDate.adding(days: 1)
    }

    func goToDate(_ date: Date) {
        selectedDate = date
    }

    // MARK: - Block Management

    func createBlock(
        title: String,
        startTime: Date,
        endTime: Date,
        colorHex: String,
        icon: String? = nil,
        notes: String? = nil
    ) {
        guard let context = modelContext else { return }

        let block = TimeBlock(
            title: title,
            startTime: startTime,
            endTime: endTime,
            colorHex: colorHex,
            icon: icon,
            notes: notes
        )

        context.insert(block)
        saveContext()
    }

    func updateBlock(_ block: TimeBlock) {
        block.updatedAt = Date()
        saveContext()
    }

    func deleteBlock(_ block: TimeBlock) {
        guard let context = modelContext else { return }
        context.delete(block)
        saveContext()
    }

    func toggleBlockCompletion(_ block: TimeBlock) {
        block.isCompleted.toggle()
        block.updatedAt = Date()
        saveContext()
    }

    func duplicateBlock(_ block: TimeBlock) {
        guard let context = modelContext else { return }

        let newStartTime = block.endTime
        let duration = block.durationMinutes
        let newEndTime = newStartTime.adding(minutes: duration)

        let newBlock = TimeBlock(
            title: block.title,
            startTime: newStartTime,
            endTime: newEndTime,
            colorHex: block.colorHex,
            icon: block.icon,
            notes: block.notes
        )

        context.insert(newBlock)
        saveContext()
    }

    // MARK: - Block Creation Sheet

    func showBlockCreation(at time: Date? = nil) {
        if let time = time {
            newBlockStartTime = time
        } else {
            // Default to next hour
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day, .hour], from: selectedDate)
            components.hour = (components.hour ?? 0) + 1
            newBlockStartTime = calendar.date(from: components) ?? selectedDate
        }
        isShowingBlockCreation = true
    }

    func showBlockDetail(for block: TimeBlock) {
        selectedBlock = block
        isShowingBlockDetail = true
    }

    // MARK: - Time Calculations

    func yPosition(for date: Date, hourHeight: CGFloat = TimelineConstants.hourHeight) -> CGFloat {
        let minutesFromStart = date.minutesFromMidnight - (startHour * 60)
        return CGFloat(minutesFromStart) * (hourHeight / 60)
    }

    func timeFromYPosition(_ y: CGFloat, hourHeight: CGFloat = TimelineConstants.hourHeight) -> Date {
        let minutesFromStart = Int(y / (hourHeight / 60))
        let totalMinutes = (startHour * 60) + minutesFromStart
        return selectedDate.startOfDay.adding(minutes: totalMinutes)
    }

    func blockHeight(for block: TimeBlock, hourHeight: CGFloat = TimelineConstants.hourHeight) -> CGFloat {
        let duration = CGFloat(block.durationMinutes)
        return duration * (hourHeight / 60)
    }

    func snapToNearestInterval(_ date: Date, interval: Int = 15) -> Date {
        let calendar = Calendar.current
        let minutes = calendar.component(.minute, from: date)
        let snappedMinutes = (minutes / interval) * interval
        return calendar.date(bySetting: .minute, value: snappedMinutes, of: date) ?? date
    }

    // MARK: - Current Time

    @Published var currentTime: Date = Date()

    private func setupCurrentTimeUpdates() {
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.currentTime = Date()
            }
            .store(in: &cancellables)
    }

    var isCurrentDaySelected: Bool {
        selectedDate.isToday
    }

    var currentTimeYPosition: CGFloat {
        yPosition(for: currentTime)
    }

    // MARK: - Persistence

    private func saveContext() {
        guard let context = modelContext else { return }
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }

    // MARK: - Block Queries

    func fetchBlocks(for date: Date) -> FetchDescriptor<TimeBlock> {
        let startOfDay = date.startOfDay
        let endOfDay = date.endOfDay

        let predicate = #Predicate<TimeBlock> { block in
            block.startTime >= startOfDay && block.startTime <= endOfDay
        }

        var descriptor = FetchDescriptor<TimeBlock>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\.startTime)]
        return descriptor
    }

    // MARK: - Conflict Detection

    func hasConflict(_ block: TimeBlock, with existingBlocks: [TimeBlock]) -> Bool {
        for existing in existingBlocks {
            if existing.id == block.id { continue }

            // Check for overlap
            if block.startTime < existing.endTime && block.endTime > existing.startTime {
                return true
            }
        }
        return false
    }

    func findConflicts(for block: TimeBlock, in blocks: [TimeBlock]) -> [TimeBlock] {
        blocks.filter { existing in
            if existing.id == block.id { return false }
            return block.startTime < existing.endTime && block.endTime > existing.startTime
        }
    }
}
