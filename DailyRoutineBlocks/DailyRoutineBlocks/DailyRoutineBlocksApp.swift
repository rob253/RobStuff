//
//  DailyRoutineBlocksApp.swift
//  DailyRoutineBlocks
//
//  A visual time-blocking app for organizing daily schedules
//

import SwiftUI
import SwiftData

@main
struct DailyRoutineBlocksApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                TimeBlock.self,
                Routine.self,
                RoutineBlock.self
            ])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
