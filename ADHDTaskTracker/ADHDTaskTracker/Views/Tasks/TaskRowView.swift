import SwiftUI

/// A single task row with completion toggle, priority, and tag indicators
/// Designed for easy tapping and satisfying completion animations
struct TaskRowView: View {
    // MARK: - Properties

    let task: TaskEntity

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var taskViewModel: TaskViewModel

    // MARK: - State

    @State private var showingDetail = false
    @State private var isAnimatingCompletion = false

    // MARK: - Body

    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            HStack(spacing: 12) {
                // Completion button
                completionButton

                // Task content
                VStack(alignment: .leading, spacing: 6) {
                    // Title row
                    HStack {
                        Text(task.title ?? "Untitled")
                            .font(.body.weight(.medium))
                            .foregroundColor(titleColor)
                            .strikethrough(task.isCompleted, color: AppColors.textSecondary(for: colorScheme))
                            .lineLimit(2)

                        Spacer()

                        // Priority indicator
                        PriorityBadge(priority: task.taskPriority)
                    }

                    // Due date and status
                    HStack(spacing: 8) {
                        // Due date
                        Label(task.dueDateDisplay, systemImage: dueDateIcon)
                            .font(.caption)
                            .foregroundColor(dueDateColor)

                        // Recurring indicator
                        if task.isRecurring {
                            Label("Recurring", systemImage: "repeat")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary(for: colorScheme))
                        }
                    }

                    // Tags
                    if !task.tagsArray.isEmpty {
                        tagsRow
                    }
                }
            }
            .padding()
            .background(AppColors.cardBackground(for: colorScheme))
            .cornerRadius(Constants.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.cardCornerRadius)
                    .stroke(statusBorderColor, lineWidth: statusBorderWidth)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            TaskDetailView(task: task)
        }
    }

    // MARK: - Completion Button

    private var completionButton: some View {
        Button(action: {
            toggleCompletion()
        }) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(completionCircleColor, lineWidth: 2)
                    .frame(width: 28, height: 28)

                // Filled circle when completed
                if task.isCompleted || isAnimatingCompletion {
                    Circle()
                        .fill(AppColors.completed)
                        .frame(width: 28, height: 28)
                        .scaleEffect(isAnimatingCompletion ? 1.2 : 1.0)
                }

                // Checkmark
                if task.isCompleted || isAnimatingCompletion {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white)
                        .scaleEffect(isAnimatingCompletion ? 1.3 : 1.0)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(task.isCompleted ? "Mark incomplete" : "Mark complete")
    }

    // MARK: - Tags Row

    private var tagsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(task.tagsArray, id: \.id) { tag in
                    TagBadge(tag: tag)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var titleColor: Color {
        task.isCompleted ? AppColors.textSecondary(for: colorScheme) : AppColors.textPrimary(for: colorScheme)
    }

    private var dueDateIcon: String {
        switch task.status {
        case .overdue: return "exclamationmark.circle.fill"
        case .dueSoon: return "clock.fill"
        case .completed: return "checkmark.circle.fill"
        case .upcoming: return "calendar"
        }
    }

    private var dueDateColor: Color {
        task.status.color
    }

    private var completionCircleColor: Color {
        task.isCompleted ? AppColors.completed : AppColors.textSecondary(for: colorScheme).opacity(0.5)
    }

    private var statusBorderColor: Color {
        switch task.status {
        case .overdue: return AppColors.overdue.opacity(0.3)
        case .dueSoon: return AppColors.dueSoon.opacity(0.3)
        default: return .clear
        }
    }

    private var statusBorderWidth: CGFloat {
        switch task.status {
        case .overdue, .dueSoon: return 2
        default: return 0
        }
    }

    // MARK: - Actions

    private func toggleCompletion() {
        // Haptic feedback
        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.impactOccurred()

        // Animate completion
        if !task.isCompleted {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                isAnimatingCompletion = true
            }

            // Delay before completing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isAnimatingCompletion = false
                    taskViewModel.toggleCompletion(for: task)
                }
            }
        } else {
            taskViewModel.toggleCompletion(for: task)
        }
    }
}

// MARK: - Task Detail View

struct TaskDetailView: View {
    // MARK: - Properties

    let task: TaskEntity

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var taskViewModel: TaskViewModel

    // MARK: - State

    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerSection

                    // Details
                    detailsSection

                    // Description
                    if let description = task.taskDescription, !description.isEmpty {
                        descriptionSection(description)
                    }

                    // Tags
                    if !task.tagsArray.isEmpty {
                        tagsSection
                    }

                    // Recurring info
                    if task.isRecurring {
                        recurringSection
                    }

                    // Actions
                    actionsSection
                }
                .padding()
            }
            .background(AppColors.background(for: colorScheme))
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: { showingEditSheet = true }) {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                EditTaskView(task: task)
            }
            .confirmationDialog("Delete Task", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    taskViewModel.deleteTask(task)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this task?")
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(task.title ?? "Untitled")
                    .font(.title2.weight(.bold))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))

                Spacer()

                PriorityBadge(priority: task.taskPriority, showLabel: true)
            }

            // Status badge
            HStack(spacing: 8) {
                Image(systemName: statusIcon)
                Text(task.status.label)
            }
            .font(.subheadline.weight(.medium))
            .foregroundColor(task.status.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(task.status.color.opacity(0.15))
            .cornerRadius(8)
        }
        .padding()
        .background(AppColors.cardBackground(for: colorScheme))
        .cornerRadius(Constants.cardCornerRadius)
    }

    private var statusIcon: String {
        switch task.status {
        case .completed: return "checkmark.circle.fill"
        case .overdue: return "exclamationmark.circle.fill"
        case .dueSoon: return "clock.fill"
        case .upcoming: return "calendar"
        }
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Due date
            DetailRow(
                icon: "calendar",
                title: "Due Date",
                value: task.dueDateDisplay,
                color: task.status.color
            )

            // Time until due
            if !task.isCompleted, let dueDate = task.dueDate {
                DetailRow(
                    icon: "clock",
                    title: "Time Remaining",
                    value: dueDate.relativeString,
                    color: AppColors.textSecondary(for: colorScheme)
                )
            }

            // Notification
            if task.notificationEnabled {
                let timing = Constants.notificationTimingOptions.first { $0.minutes == Int(task.notificationMinutesBefore) }
                DetailRow(
                    icon: "bell.fill",
                    title: "Reminder",
                    value: timing?.label ?? "Custom",
                    color: AppColors.primaryTeal
                )
            }

            // Created date
            if let createdAt = task.createdAt {
                DetailRow(
                    icon: "plus.circle",
                    title: "Created",
                    value: createdAt.displayString,
                    color: AppColors.textSecondary(for: colorScheme)
                )
            }

            // Completed date
            if let completedAt = task.completedAt {
                DetailRow(
                    icon: "checkmark.circle",
                    title: "Completed",
                    value: completedAt.displayString,
                    color: AppColors.completed
                )
            }
        }
        .padding()
        .background(AppColors.cardBackground(for: colorScheme))
        .cornerRadius(Constants.cardCornerRadius)
    }

    // MARK: - Description Section

    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary(for: colorScheme))

            Text(description)
                .font(.body)
                .foregroundColor(AppColors.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.cardBackground(for: colorScheme))
        .cornerRadius(Constants.cardCornerRadius)
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary(for: colorScheme))

            FlowLayout(spacing: 8) {
                ForEach(task.tagsArray, id: \.id) { tag in
                    TagBadge(tag: tag, showLabel: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.cardBackground(for: colorScheme))
        .cornerRadius(Constants.cardCornerRadius)
    }

    // MARK: - Recurring Section

    private var recurringSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recurring")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary(for: colorScheme))

            HStack {
                Image(systemName: "repeat")
                    .foregroundColor(AppColors.primaryTeal)

                let pattern = Constants.recurringPatterns.first { $0.pattern == task.recurringPattern }
                Text(pattern?.description ?? "Repeats \(task.recurringPattern ?? "periodically")")
                    .foregroundColor(AppColors.textSecondary(for: colorScheme))
            }

            if let endDate = task.recurringEndDate {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(AppColors.textSecondary(for: colorScheme))
                    Text("Until \(endDate.displayString)")
                        .foregroundColor(AppColors.textSecondary(for: colorScheme))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.cardBackground(for: colorScheme))
        .cornerRadius(Constants.cardCornerRadius)
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Complete/Incomplete button
            Button(action: {
                let feedback = UIImpactFeedbackGenerator(style: .medium)
                feedback.impactOccurred()
                taskViewModel.toggleCompletion(for: task)
            }) {
                HStack {
                    Image(systemName: task.isCompleted ? "arrow.uturn.backward" : "checkmark.circle.fill")
                    Text(task.isCompleted ? "Mark Incomplete" : "Mark Complete")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(task.isCompleted ? AppColors.softBlue : AppColors.completed)
                .cornerRadius(Constants.buttonCornerRadius)
            }

            // Edit button
            Button(action: { showingEditSheet = true }) {
                HStack {
                    Image(systemName: "pencil")
                    Text("Edit Task")
                }
                .font(.headline)
                .foregroundColor(AppColors.primaryTeal)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.primaryTeal.opacity(0.15))
                .cornerRadius(Constants.buttonCornerRadius)
            }
        }
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            Text(title)
                .foregroundColor(AppColors.textSecondary(for: colorScheme))

            Spacer()

            Text(value)
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
        }
    }
}

// MARK: - Preview

#Preview {
    TaskRowView(task: {
        let context = PersistenceController.preview.container.viewContext
        let task = TaskEntity(context: context)
        task.id = UUID()
        task.title = "Complete project report"
        task.taskDescription = "Finish the quarterly report"
        task.dueDate = Date().addingTimeInterval(3600)
        task.priority = 2
        task.isCompleted = false
        return task
    }())
    .environmentObject(TaskViewModel(context: PersistenceController.preview.container.viewContext))
    .padding()
}
