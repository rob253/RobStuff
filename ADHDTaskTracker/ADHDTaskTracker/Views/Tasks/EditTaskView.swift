import SwiftUI

/// Edit task view for modifying existing tasks
struct EditTaskView: View {
    // MARK: - Properties

    let task: TaskEntity

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var taskViewModel: TaskViewModel
    @EnvironmentObject private var tagViewModel: TagViewModel

    // MARK: - State

    @State private var title: String
    @State private var description: String
    @State private var dueDate: Date
    @State private var priority: TaskPriority
    @State private var selectedTags: Set<TagEntity>
    @State private var notificationEnabled: Bool
    @State private var notificationMinutes: Int
    @State private var isRecurring: Bool
    @State private var recurringPattern: String
    @State private var recurringEndDate: Date?
    @State private var hasRecurringEndDate: Bool

    @State private var showingTagPicker = false
    @State private var hasChanges = false

    // MARK: - Initialization

    init(task: TaskEntity) {
        self.task = task

        _title = State(initialValue: task.title ?? "")
        _description = State(initialValue: task.taskDescription ?? "")
        _dueDate = State(initialValue: task.dueDate ?? Date())
        _priority = State(initialValue: task.taskPriority)
        _selectedTags = State(initialValue: Set(task.tagsArray))
        _notificationEnabled = State(initialValue: task.notificationEnabled)
        _notificationMinutes = State(initialValue: Int(task.notificationMinutesBefore))
        _isRecurring = State(initialValue: task.isRecurring)
        _recurringPattern = State(initialValue: task.recurringPattern ?? "daily")
        _recurringEndDate = State(initialValue: task.recurringEndDate)
        _hasRecurringEndDate = State(initialValue: task.recurringEndDate != nil)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info Section
                Section("Task Details") {
                    TextField("Title", text: $title)
                        .onChange(of: title) { _, _ in hasChanges = true }

                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                        .onChange(of: description) { _, _ in hasChanges = true }
                }

                // Priority Section
                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases) { p in
                            Label(p.label, systemImage: p.icon)
                                .tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: priority) { _, _ in hasChanges = true }
                }

                // Due Date Section
                Section("Due Date") {
                    DatePicker(
                        "Due",
                        selection: $dueDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .onChange(of: dueDate) { _, _ in hasChanges = true }
                }

                // Tags Section
                Section {
                    ForEach(tagViewModel.tags, id: \.id) { tag in
                        HStack {
                            Circle()
                                .fill(tag.color)
                                .frame(width: 12, height: 12)

                            Text(tag.name ?? "Tag")

                            Spacer()

                            if selectedTags.contains(tag) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColors.primaryTeal)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedTags.contains(tag) {
                                selectedTags.remove(tag)
                            } else {
                                selectedTags.insert(tag)
                            }
                            hasChanges = true
                        }
                    }

                    Button(action: { showingTagPicker = true }) {
                        Label("Manage Tags", systemImage: "tag")
                    }
                } header: {
                    Text("Tags")
                }

                // Notification Section
                Section("Reminder") {
                    Toggle("Enable Reminder", isOn: $notificationEnabled)
                        .tint(AppColors.primaryTeal)
                        .onChange(of: notificationEnabled) { _, _ in hasChanges = true }

                    if notificationEnabled {
                        Picker("Remind me", selection: $notificationMinutes) {
                            ForEach(Constants.notificationTimingOptions) { timing in
                                Text(timing.label).tag(timing.minutes)
                            }
                        }
                        .onChange(of: notificationMinutes) { _, _ in hasChanges = true }
                    }
                }

                // Recurring Section
                Section("Recurring") {
                    Toggle("Repeating Task", isOn: $isRecurring)
                        .tint(AppColors.primaryTeal)
                        .onChange(of: isRecurring) { _, _ in hasChanges = true }

                    if isRecurring {
                        Picker("Repeat", selection: $recurringPattern) {
                            ForEach(Constants.recurringPatterns) { pattern in
                                Text(pattern.label).tag(pattern.pattern)
                            }
                        }
                        .onChange(of: recurringPattern) { _, _ in hasChanges = true }

                        Toggle("End Date", isOn: $hasRecurringEndDate)
                            .tint(AppColors.primaryTeal)
                            .onChange(of: hasRecurringEndDate) { _, _ in hasChanges = true }

                        if hasRecurringEndDate {
                            DatePicker(
                                "End on",
                                selection: Binding(
                                    get: { recurringEndDate ?? Date().addingTimeInterval(86400 * 30) },
                                    set: { recurringEndDate = $0 }
                                ),
                                in: dueDate...,
                                displayedComponents: .date
                            )
                            .onChange(of: recurringEndDate) { _, _ in hasChanges = true }
                        }
                    }
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .font(.headline)
                    .disabled(title.isEmpty || !hasChanges)
                }
            }
            .sheet(isPresented: $showingTagPicker) {
                TagManagementView()
            }
        }
    }

    // MARK: - Actions

    private func saveChanges() {
        // Haptic feedback
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)

        taskViewModel.updateTask(
            task,
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

// MARK: - Preview

#Preview {
    EditTaskView(task: {
        let context = PersistenceController.preview.container.viewContext
        let task = TaskEntity(context: context)
        task.id = UUID()
        task.title = "Sample Task"
        task.taskDescription = "This is a sample task"
        task.dueDate = Date()
        task.priority = 1
        return task
    }())
    .environmentObject(TaskViewModel(context: PersistenceController.preview.container.viewContext))
    .environmentObject(TagViewModel(context: PersistenceController.preview.container.viewContext))
}
