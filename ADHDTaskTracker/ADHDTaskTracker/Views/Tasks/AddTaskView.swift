import SwiftUI

/// Quick-add task view designed for minimal friction
/// ADHD-friendly: Large buttons, smart defaults, minimal required fields
struct AddTaskView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var taskViewModel: TaskViewModel
    @EnvironmentObject private var tagViewModel: TagViewModel

    // MARK: - State

    @State private var title = ""
    @State private var description = ""
    @State private var dueDate = Date().addingTimeInterval(3600) // Default: 1 hour from now
    @State private var priority: TaskPriority = .medium
    @State private var selectedTags: Set<TagEntity> = []
    @State private var notificationEnabled = true
    @State private var notificationMinutes: Int = Int(Constants.defaultNotificationMinutes)
    @State private var isRecurring = false
    @State private var recurringPattern = "daily"
    @State private var recurringEndDate: Date?
    @State private var hasRecurringEndDate = false

    @State private var showingTagPicker = false
    @State private var showingAdvancedOptions = false

    @FocusState private var isTitleFocused: Bool

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Title input (required)
                    titleSection

                    // Quick priority selection
                    prioritySection

                    // Quick due date selection
                    dueDateSection

                    // Quick tag selection
                    tagSection

                    // Advanced options (collapsed by default)
                    advancedSection
                }
                .padding()
            }
            .background(AppColors.background(for: colorScheme))
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        addTask()
                    }
                    .font(.headline)
                    .disabled(title.isEmpty)
                }
            }
            .onAppear {
                isTitleFocused = true
            }
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What do you need to do?")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary(for: colorScheme))

            TextField("Task title", text: $title)
                .font(.title3)
                .padding()
                .background(AppColors.cardBackground(for: colorScheme))
                .cornerRadius(Constants.cardCornerRadius)
                .focused($isTitleFocused)
        }
    }

    // MARK: - Priority Section

    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Priority")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary(for: colorScheme))

            HStack(spacing: 12) {
                ForEach(TaskPriority.allCases) { p in
                    PriorityButton(
                        priority: p,
                        isSelected: priority == p,
                        action: { priority = p }
                    )
                }
            }
        }
    }

    // MARK: - Due Date Section

    private var dueDateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("When is it due?")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary(for: colorScheme))

            // Quick options
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    QuickDateButton(
                        label: "In 1 hour",
                        isSelected: isWithinHour,
                        action: { dueDate = Date().addingTimeInterval(3600) }
                    )
                    QuickDateButton(
                        label: "Today",
                        isSelected: dueDate.isToday && !isWithinHour,
                        action: { dueDate = todayEvening }
                    )
                    QuickDateButton(
                        label: "Tomorrow",
                        isSelected: dueDate.isTomorrow,
                        action: { dueDate = tomorrowMorning }
                    )
                    QuickDateButton(
                        label: "This Week",
                        isSelected: isLaterThisWeek,
                        action: { dueDate = endOfWeek }
                    )
                }
            }

            // Date picker for custom time
            DatePicker(
                "Custom date & time",
                selection: $dueDate,
                in: Date()...,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.compact)
            .padding()
            .background(AppColors.cardBackground(for: colorScheme))
            .cornerRadius(Constants.cardCornerRadius)
        }
    }

    // Quick date helpers
    private var isWithinHour: Bool {
        let hourFromNow = Date().addingTimeInterval(3600)
        return abs(dueDate.timeIntervalSince(hourFromNow)) < 300 // Within 5 minutes of 1 hour from now
    }

    private var todayEvening: Date {
        Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
    }

    private var tomorrowMorning: Date {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }

    private var endOfWeek: Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let daysUntilFriday = (6 - weekday + 7) % 7
        let friday = calendar.date(byAdding: .day, value: daysUntilFriday, to: Date()) ?? Date()
        return calendar.date(bySettingHour: 17, minute: 0, second: 0, of: friday) ?? friday
    }

    private var isLaterThisWeek: Bool {
        dueDate.isThisWeek && !dueDate.isToday && !dueDate.isTomorrow
    }

    // MARK: - Tag Section

    private var tagSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tags")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))

                Spacer()

                Button(action: { showingTagPicker = true }) {
                    Text("Manage")
                        .font(.subheadline)
                        .foregroundColor(AppColors.primaryTeal)
                }
            }

            // Quick tag selection
            FlowLayout(spacing: 8) {
                ForEach(tagViewModel.tags, id: \.id) { tag in
                    TagToggleButton(
                        tag: tag,
                        isSelected: selectedTags.contains(tag),
                        action: {
                            if selectedTags.contains(tag) {
                                selectedTags.remove(tag)
                            } else {
                                selectedTags.insert(tag)
                            }
                        }
                    )
                }
            }
        }
        .sheet(isPresented: $showingTagPicker) {
            TagManagementView()
        }
    }

    // MARK: - Advanced Section

    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation {
                    showingAdvancedOptions.toggle()
                }
            }) {
                HStack {
                    Text("Advanced Options")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary(for: colorScheme))

                    Spacer()

                    Image(systemName: showingAdvancedOptions ? "chevron.up" : "chevron.down")
                        .foregroundColor(AppColors.textSecondary(for: colorScheme))
                }
            }

            if showingAdvancedOptions {
                VStack(spacing: 16) {
                    // Description
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description (optional)")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary(for: colorScheme))

                        TextField("Add details...", text: $description, axis: .vertical)
                            .lineLimit(3...6)
                            .padding()
                            .background(AppColors.cardBackground(for: colorScheme))
                            .cornerRadius(Constants.cardCornerRadius)
                    }

                    // Notification settings
                    notificationSection

                    // Recurring settings
                    recurringSection
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(AppColors.secondaryBackground(for: colorScheme))
        .cornerRadius(Constants.cardCornerRadius)
    }

    // MARK: - Notification Section

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $notificationEnabled) {
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundColor(AppColors.primaryTeal)
                    Text("Reminder")
                }
            }
            .tint(AppColors.primaryTeal)

            if notificationEnabled {
                Picker("Remind me", selection: $notificationMinutes) {
                    ForEach(Constants.notificationTimingOptions) { timing in
                        Text(timing.label).tag(timing.minutes)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    // MARK: - Recurring Section

    private var recurringSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $isRecurring) {
                HStack {
                    Image(systemName: "repeat")
                        .foregroundColor(AppColors.primaryTeal)
                    Text("Repeating Task")
                }
            }
            .tint(AppColors.primaryTeal)

            if isRecurring {
                Picker("Repeat", selection: $recurringPattern) {
                    ForEach(Constants.recurringPatterns) { pattern in
                        Text(pattern.label).tag(pattern.pattern)
                    }
                }
                .pickerStyle(.segmented)

                Toggle(isOn: $hasRecurringEndDate) {
                    Text("End Date")
                }
                .tint(AppColors.primaryTeal)

                if hasRecurringEndDate {
                    DatePicker(
                        "End repeating on",
                        selection: Binding(
                            get: { recurringEndDate ?? Date().addingTimeInterval(86400 * 30) },
                            set: { recurringEndDate = $0 }
                        ),
                        in: dueDate...,
                        displayedComponents: .date
                    )
                }
            }
        }
    }

    // MARK: - Actions

    private func addTask() {
        // Haptic feedback
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)

        taskViewModel.createTask(
            title: title,
            description: description.isEmpty ? nil : description,
            dueDate: dueDate,
            priority: priority,
            tags: Array(selectedTags),
            notificationEnabled: notificationEnabled,
            notificationMinutesBefore: Int32(notificationMinutes),
            isRecurring: isRecurring,
            recurringPattern: isRecurring ? recurringPattern : nil,
            recurringInterval: 1,
            recurringEndDate: hasRecurringEndDate ? recurringEndDate : nil
        )

        dismiss()
    }
}

// MARK: - Priority Button

struct PriorityButton: View {
    let priority: TaskPriority
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: priority.icon)
                    .font(.title2)
                Text(priority.label)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .white : priority.color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? priority.color : priority.color.opacity(0.15))
            .cornerRadius(Constants.buttonCornerRadius)
        }
    }
}

// MARK: - Quick Date Button

struct QuickDateButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundColor(isSelected ? .white : AppColors.primaryTeal)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? AppColors.primaryTeal : AppColors.primaryTeal.opacity(0.15))
                .cornerRadius(20)
        }
    }
}

// MARK: - Tag Toggle Button

struct TagToggleButton: View {
    let tag: TagEntity
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Circle()
                    .fill(tag.color)
                    .frame(width: 8, height: 8)
                Text(tag.name ?? "Tag")
                    .font(.subheadline)
            }
            .foregroundColor(isSelected ? .white : tag.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? tag.color : tag.color.opacity(0.15))
            .cornerRadius(16)
        }
    }
}

// MARK: - Preview

#Preview {
    AddTaskView()
        .environmentObject(TaskViewModel(context: PersistenceController.preview.container.viewContext))
        .environmentObject(TagViewModel(context: PersistenceController.preview.container.viewContext))
}
