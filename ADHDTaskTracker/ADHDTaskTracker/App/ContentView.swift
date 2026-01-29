import SwiftUI

/// Main content view with tab-based navigation
/// Designed with ADHD users in mind - simple, clean, minimal cognitive load
struct ContentView: View {
    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var taskViewModel: TaskViewModel
    @EnvironmentObject private var notificationManager: NotificationManager

    // MARK: - State

    @State private var selectedTab: Tab = .today
    @State private var showingAddTask = false
    @State private var showingSearch = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background color
            AppColors.background(for: colorScheme)
                .ignoresSafeArea()

            TabView(selection: $selectedTab) {
                // Today Tab
                TodayView()
                    .tabItem {
                        Label("Today", systemImage: "sun.max.fill")
                    }
                    .tag(Tab.today)

                // All Tasks Tab
                TaskListView()
                    .tabItem {
                        Label("Tasks", systemImage: "checklist")
                    }
                    .tag(Tab.tasks)

                // Calendar Tab
                CalendarTabView()
                    .tabItem {
                        Label("Calendar", systemImage: "calendar")
                    }
                    .tag(Tab.calendar)

                // Progress Tab
                AnalyticsView()
                    .tabItem {
                        Label("Progress", systemImage: "chart.bar.fill")
                    }
                    .tag(Tab.progress)

                // Settings Tab
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(Tab.settings)
            }
            .tint(AppColors.primaryTeal)

            // Floating Add Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    addButton
                        .padding(.trailing, 20)
                        .padding(.bottom, 80) // Above tab bar
                }
            }
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView()
        }
        .onAppear {
            checkNotificationPermission()
        }
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button(action: {
            // Haptic feedback for satisfying interaction
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()

            showingAddTask = true
        }) {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(AppColors.primaryTeal)
                .clipShape(Circle())
                .shadow(color: AppColors.primaryTeal.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .accessibilityLabel("Add new task")
        .accessibilityHint("Double tap to create a new task")
    }

    // MARK: - Helper Methods

    private func checkNotificationPermission() {
        notificationManager.checkAuthorizationStatus()
    }
}

// MARK: - Tab Enum

enum Tab: String, CaseIterable {
    case today
    case tasks
    case calendar
    case progress
    case settings
}

// MARK: - Today View

/// Shows tasks for today with encouraging messaging
struct TodayView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var taskViewModel: TaskViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with greeting
                    headerSection

                    // Quick stats
                    quickStatsSection

                    // Today's tasks
                    todayTasksSection

                    // Overdue section (if any)
                    if !overdueTasks.isEmpty {
                        overdueSection
                    }
                }
                .padding()
            }
            .background(AppColors.background(for: colorScheme))
            .navigationTitle("Today")
            .refreshable {
                taskViewModel.fetchTasks()
            }
        }
    }

    // MARK: - Computed Properties

    private var todayTasks: [TaskEntity] {
        taskViewModel.allTasks.filter { $0.isDueToday && !$0.isCompleted }
    }

    private var completedTodayTasks: [TaskEntity] {
        taskViewModel.allTasks.filter { $0.isDueToday && $0.isCompleted }
    }

    private var overdueTasks: [TaskEntity] {
        taskViewModel.allTasks.filter { $0.status == .overdue }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greetingMessage)
                .font(.title2.weight(.semibold))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))

            Text(motivationalMessage)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.cardBackground(for: colorScheme))
        .cornerRadius(Constants.cardCornerRadius)
    }

    private var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning!"
        case 12..<17: return "Good afternoon!"
        default: return "Good evening!"
        }
    }

    private var motivationalMessage: String {
        let remaining = todayTasks.count
        let completed = completedTodayTasks.count

        if remaining == 0 && completed == 0 {
            return "No tasks scheduled for today. Time to relax!"
        } else if remaining == 0 {
            return "Amazing! You've completed all \(completed) task\(completed == 1 ? "" : "s") today!"
        } else if completed > 0 {
            return "You've completed \(completed) task\(completed == 1 ? "" : "s"). \(remaining) more to go!"
        } else {
            return "You have \(remaining) task\(remaining == 1 ? "" : "s") to tackle today."
        }
    }

    // MARK: - Quick Stats

    private var quickStatsSection: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Due Today",
                value: "\(todayTasks.count)",
                icon: "clock.fill",
                color: AppColors.primaryTeal
            )

            StatCard(
                title: "Completed",
                value: "\(completedTodayTasks.count)",
                icon: "checkmark.circle.fill",
                color: AppColors.completed
            )

            if !overdueTasks.isEmpty {
                StatCard(
                    title: "Overdue",
                    value: "\(overdueTasks.count)",
                    icon: "exclamationmark.circle.fill",
                    color: AppColors.overdue
                )
            }
        }
    }

    // MARK: - Today Tasks

    private var todayTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Tasks")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary(for: colorScheme))

            if todayTasks.isEmpty {
                EmptyStateView(
                    icon: "sun.max.fill",
                    title: "All clear!",
                    message: "No pending tasks for today.",
                    color: AppColors.sageGreen
                )
            } else {
                ForEach(todayTasks, id: \.id) { task in
                    TaskRowView(task: task)
                }
            }
        }
    }

    // MARK: - Overdue Section

    private var overdueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(AppColors.overdue)
                Text("Overdue")
                    .font(.headline)
                    .foregroundColor(AppColors.overdue)
            }

            ForEach(overdueTasks, id: \.id) { task in
                TaskRowView(task: task)
            }
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title.weight(.bold))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))

            Text(title)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppColors.cardBackground(for: colorScheme))
        .cornerRadius(Constants.cardCornerRadius)
    }
}

// MARK: - Calendar Tab View (Wrapper)

struct CalendarTabView: View {
    var body: some View {
        NavigationStack {
            CalendarView()
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(TaskViewModel(context: PersistenceController.preview.container.viewContext))
        .environmentObject(TagViewModel(context: PersistenceController.preview.container.viewContext))
        .environmentObject(AnalyticsViewModel(context: PersistenceController.preview.container.viewContext))
        .environmentObject(NotificationManager.shared)
}
