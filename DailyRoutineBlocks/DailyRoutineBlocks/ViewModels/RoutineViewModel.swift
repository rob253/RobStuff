//
//  RoutineViewModel.swift
//  DailyRoutineBlocks
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
class RoutineViewModel: ObservableObject {
    @Published var selectedRoutine: Routine?
    @Published var isShowingRoutineDetail: Bool = false
    @Published var isShowingRoutineCreation: Bool = false

    private var modelContext: ModelContext?

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Routine Management

    func createRoutine(name: String, blocks: [RoutineBlock] = []) -> Routine {
        guard let context = modelContext else {
            fatalError("ModelContext not set")
        }

        let routine = Routine(name: name, blocks: blocks)
        context.insert(routine)
        saveContext()
        return routine
    }

    func updateRoutine(_ routine: Routine) {
        routine.updatedAt = Date()
        saveContext()
    }

    func deleteRoutine(_ routine: Routine) {
        guard let context = modelContext else { return }
        context.delete(routine)
        saveContext()
    }

    func duplicateRoutine(_ routine: Routine) -> Routine {
        guard let context = modelContext else {
            fatalError("ModelContext not set")
        }

        let newBlocks = routine.blocks.map { block in
            RoutineBlock(
                title: block.title,
                startMinutesFromMidnight: block.startMinutesFromMidnight,
                durationMinutes: block.durationMinutes,
                colorHex: block.colorHex,
                icon: block.icon,
                notes: block.notes
            )
        }

        let newRoutine = Routine(
            name: "\(routine.name) (Copy)",
            blocks: newBlocks
        )

        context.insert(newRoutine)
        saveContext()
        return newRoutine
    }

    // MARK: - Routine Block Management

    func addBlockToRoutine(
        _ routine: Routine,
        title: String,
        startMinutesFromMidnight: Int,
        durationMinutes: Int,
        colorHex: String,
        icon: String? = nil,
        notes: String? = nil
    ) {
        let block = RoutineBlock(
            title: title,
            startMinutesFromMidnight: startMinutesFromMidnight,
            durationMinutes: durationMinutes,
            colorHex: colorHex,
            icon: icon,
            notes: notes
        )
        routine.blocks.append(block)
        routine.updatedAt = Date()
        saveContext()
    }

    func removeBlockFromRoutine(_ routine: Routine, block: RoutineBlock) {
        routine.blocks.removeAll { $0.id == block.id }
        routine.updatedAt = Date()
        saveContext()
    }

    // MARK: - Apply Routine to Day

    func applyRoutine(_ routine: Routine, toDate date: Date, using context: ModelContext) {
        let timeBlocks = routine.applyToDate(date)
        for block in timeBlocks {
            context.insert(block)
        }
        saveContext()
    }

    // MARK: - Create Routine from Existing Blocks

    func createRoutineFromBlocks(name: String, blocks: [TimeBlock]) -> Routine {
        guard let context = modelContext else {
            fatalError("ModelContext not set")
        }

        let routineBlocks = blocks.map { block in
            RoutineBlock(
                title: block.title,
                startMinutesFromMidnight: block.startTime.minutesFromMidnight,
                durationMinutes: block.durationMinutes,
                colorHex: block.colorHex,
                icon: block.icon,
                notes: block.notes
            )
        }

        let routine = Routine(name: name, blocks: routineBlocks)
        context.insert(routine)
        saveContext()
        return routine
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

    // MARK: - Fetch Descriptor

    static var fetchDescriptor: FetchDescriptor<Routine> {
        var descriptor = FetchDescriptor<Routine>()
        descriptor.sortBy = [SortDescriptor(\.name)]
        return descriptor
    }
}
