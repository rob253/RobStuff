//
//  ContentView.swift
//  DailyRoutineBlocks
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [TimeBlock.self, Routine.self, RoutineBlock.self], inMemory: true)
}
