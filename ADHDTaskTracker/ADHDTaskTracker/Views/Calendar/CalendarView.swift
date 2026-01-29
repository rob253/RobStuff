import SwiftUI

/// Calendar view showing tasks in month/week views
/// Provides visual overview of upcoming tasks
struct CalendarView: View {
    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var taskViewModel: TaskViewModel

    // MARK: - State

    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var viewMode: CalendarViewMode = .month
    @State private var showingTasksForDate = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // View mode picker
            viewModePicker

            if viewMode == .month {
                monthView
            } else {
                weekView
            }

            Divider()

            // Tasks for selected date
            selectedDateTasks
        }
        .background(AppColors.background(for: colorScheme))
        .navigationTitle("Calendar")
    }

    // MARK: - View Mode Picker

    private var viewModePicker: some View {
        Picker("View", selection: $viewMode) {
            Text("Month").tag(CalendarViewMode.month)
            Text("Week").tag(CalendarViewMode.week)
        }
        .pickerStyle(.segmented)
        .padding()
    }

    // MARK: - Month View

    private var monthView: some View {
        VStack(spacing: 12) {
            // Month navigation
            monthNavigationHeader

            // Day of week headers
            dayOfWeekHeader

            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(datesForMonth, id: \.self) { date in
                    CalendarDayCell(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                        isCurrentMonth: Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month),
                        taskCount: taskViewModel.tasks(for: date).filter { !$0.isCompleted }.count,
                        hasOverdue: taskViewModel.tasks(for: date).contains { $0.status == .overdue }
                    )
                    .onTapGesture {
                        selectedDate = date
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Month Navigation

    private var monthNavigationHeader: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title3)
            }

            Spacer()

            Text(monthYearString)
                .font(.title2.weight(.semibold))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))

            Spacer()

            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title3)
            }
        }
        .padding(.horizontal)
        .tint(AppColors.primaryTeal)
    }

    // MARK: - Day of Week Header

    private var dayOfWeekHeader: some View {
        HStack {
            ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { day in
                Text(day)
                    .font(.caption.weight(.medium))
                    .foregroundColor(AppColors.textSecondary(for: colorScheme))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Week View

    private var weekView: some View {
        VStack(spacing: 12) {
            // Week navigation
            weekNavigationHeader

            // Days of the week
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(daysInSelectedWeek, id: \.self) { date in
                        WeekDayColumn(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            tasks: taskViewModel.tasks(for: date)
                        )
                        .onTapGesture {
                            selectedDate = date
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Week Navigation

    private var weekNavigationHeader: some View {
        HStack {
            Button(action: previousWeek) {
                Image(systemName: "chevron.left")
                    .font(.title3)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(weekRangeString)
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))

                if !Calendar.current.isDate(selectedDate, equalTo: Date(), toGranularity: .weekOfYear) {
                    Button("Today") {
                        selectedDate = Date()
                        currentMonth = Date()
                    }
                    .font(.caption)
                    .foregroundColor(AppColors.primaryTeal)
                }
            }

            Spacer()

            Button(action: nextWeek) {
                Image(systemName: "chevron.right")
                    .font(.title3)
            }
        }
        .padding(.horizontal)
        .tint(AppColors.primaryTeal)
    }

    // MARK: - Selected Date Tasks

    private var selectedDateTasks: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(selectedDateString)
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))

                Spacer()

                Text("\(tasksForSelectedDate.count) task\(tasksForSelectedDate.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary(for: colorScheme))
            }
            .padding(.horizontal)
            .padding(.top, 12)

            if tasksForSelectedDate.isEmpty {
                EmptyStateView(
                    icon: "calendar",
                    title: "No tasks",
                    message: "No tasks scheduled for this day.",
                    color: AppColors.sageGreen
                )
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(tasksForSelectedDate, id: \.id) { task in
                            TaskRowView(task: task)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var datesForMonth: [Date] {
        Calendar.current.generateDates(for: currentMonth)
    }

    private var daysInSelectedWeek: [Date] {
        selectedDate.daysInWeek
    }

    private var tasksForSelectedDate: [TaskEntity] {
        taskViewModel.tasks(for: selectedDate)
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    private var weekRangeString: String {
        let start = selectedDate.startOfWeek
        let end = selectedDate.endOfWeek
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }

    private var selectedDateString: String {
        if selectedDate.isToday {
            return "Today"
        } else if selectedDate.isTomorrow {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: selectedDate)
        }
    }

    // MARK: - Navigation Actions

    private func previousMonth() {
        if let newMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) {
            withAnimation {
                currentMonth = newMonth
            }
        }
    }

    private func nextMonth() {
        if let newMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) {
            withAnimation {
                currentMonth = newMonth
            }
        }
    }

    private func previousWeek() {
        if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate) {
            withAnimation {
                selectedDate = newDate
                currentMonth = newDate
            }
        }
    }

    private func nextWeek() {
        if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate) {
            withAnimation {
                selectedDate = newDate
                currentMonth = newDate
            }
        }
    }
}

// MARK: - Calendar View Mode

enum CalendarViewMode: String, CaseIterable {
    case month
    case week
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isCurrentMonth: Bool
    let taskCount: Int
    let hasOverdue: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 4) {
            Text(date.dayNumber)
                .font(.system(.body, design: .rounded).weight(isSelected ? .bold : .regular))
                .foregroundColor(textColor)

            // Task indicator dots
            if taskCount > 0 {
                HStack(spacing: 2) {
                    ForEach(0..<min(taskCount, 3), id: \.self) { _ in
                        Circle()
                            .fill(hasOverdue ? AppColors.overdue : AppColors.primaryTeal)
                            .frame(width: 4, height: 4)
                    }
                    if taskCount > 3 {
                        Text("+")
                            .font(.system(size: 8))
                            .foregroundColor(AppColors.textSecondary(for: colorScheme))
                    }
                }
            }
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isToday ? AppColors.primaryTeal : .clear, lineWidth: 2)
        )
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var textColor: Color {
        if isSelected {
            return .white
        } else if !isCurrentMonth {
            return AppColors.textSecondary(for: colorScheme).opacity(0.5)
        } else if isToday {
            return AppColors.primaryTeal
        } else {
            return AppColors.textPrimary(for: colorScheme)
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return AppColors.primaryTeal
        } else {
            return .clear
        }
    }
}

// MARK: - Week Day Column

struct WeekDayColumn: View {
    let date: Date
    let isSelected: Bool
    let tasks: [TaskEntity]

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 8) {
            // Day header
            VStack(spacing: 2) {
                Text(date.shortDayName)
                    .font(.caption.weight(.medium))
                    .foregroundColor(AppColors.textSecondary(for: colorScheme))

                Text(date.dayNumber)
                    .font(.title2.weight(isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .white : textColor)
                    .frame(width: 36, height: 36)
                    .background(isSelected ? AppColors.primaryTeal : .clear)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(isToday && !isSelected ? AppColors.primaryTeal : .clear, lineWidth: 2)
                    )
            }

            // Mini task list
            VStack(spacing: 4) {
                ForEach(tasks.prefix(3), id: \.id) { task in
                    MiniTaskPill(task: task)
                }

                if tasks.count > 3 {
                    Text("+\(tasks.count - 3) more")
                        .font(.caption2)
                        .foregroundColor(AppColors.textSecondary(for: colorScheme))
                }
            }

            Spacer()
        }
        .frame(width: 80, height: 180)
        .padding(.vertical, 8)
        .background(isSelected ? AppColors.primaryTeal.opacity(0.1) : .clear)
        .cornerRadius(12)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var textColor: Color {
        isToday ? AppColors.primaryTeal : AppColors.textPrimary(for: colorScheme)
    }
}

// MARK: - Mini Task Pill

struct MiniTaskPill: View {
    let task: TaskEntity

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(priorityColor)
                .frame(width: 6, height: 6)

            Text(task.title ?? "")
                .font(.caption2)
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground(for: colorScheme))
        .cornerRadius(4)
        .opacity(task.isCompleted ? 0.5 : 1.0)
    }

    private var priorityColor: Color {
        AppColors.forPriority(Int(task.priority))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CalendarView()
            .environmentObject(TaskViewModel(context: PersistenceController.preview.container.viewContext))
    }
}
