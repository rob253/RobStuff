//
//  MainTabView.swift
//  DailyRoutineBlocks
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .timeline

    enum Tab: String {
        case timeline
        case routines
        case settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TimelineView()
                .tabItem {
                    Label("Timeline", systemImage: "calendar.day.timeline.left")
                }
                .tag(Tab.timeline)

            RoutineListView()
                .tabItem {
                    Label("Routines", systemImage: "repeat")
                }
                .tag(Tab.routines)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(Tab.settings)
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .modelContainer(for: [TimeBlock.self, Routine.self, RoutineBlock.self], inMemory: true)
}
