import SwiftUI

/// Main task list view with filtering, sorting, and search
struct TaskListView: View {
    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var taskViewModel: TaskViewModel
    @EnvironmentObject private var tagViewModel: TagViewModel

    // MARK: - State

    @State private var showingFilterSheet = false
    @State private var showingSortSheet = false
    @State private var searchText = ""

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter chips
                if hasActiveFilters {
                    activeFiltersView
                }

                // Task list
                if taskViewModel.displayedTasks.isEmpty {
                    emptyStateView
                } else {
                    taskListContent
                }
            }
            .background(AppColors.background(for: colorScheme))
            .navigationTitle("Tasks")
            .searchable(text: $searchText, prompt: "Search tasks...")
            .onChange(of: searchText) { _, newValue in
                taskViewModel.searchQuery = newValue
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    filterButton
                }
                ToolbarItem(placement: .topBarTrailing) {
                    sortButton
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterSheetView()
            }
            .sheet(isPresented: $showingSortSheet) {
                SortSheetView()
            }
            .refreshable {
                taskViewModel.fetchTasks()
            }
        }
    }

    // MARK: - Computed Properties

    private var hasActiveFilters: Bool {
        taskViewModel.currentFilter != .all ||
        !taskViewModel.selectedTags.isEmpty ||
        taskViewModel.selectedPriority != nil
    }

    // MARK: - Filter Button

    private var filterButton: some View {
        Button(action: { showingFilterSheet = true }) {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                if hasActiveFilters {
                    Circle()
                        .fill(AppColors.primaryTeal)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .tint(AppColors.primaryTeal)
    }

    // MARK: - Sort Button

    private var sortButton: some View {
        Button(action: { showingSortSheet = true }) {
            Image(systemName: "arrow.up.arrow.down")
        }
        .tint(AppColors.primaryTeal)
    }

    // MARK: - Active Filters View

    private var activeFiltersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Main filter chip
                if taskViewModel.currentFilter != .all {
                    FilterChip(
                        label: taskViewModel.currentFilter.rawValue,
                        onRemove: {
                            taskViewModel.currentFilter = .all
                        }
                    )
                }

                // Priority filter chip
                if let priority = taskViewModel.selectedPriority {
                    FilterChip(
                        label: priority.label,
                        color: priority.color,
                        onRemove: {
                            taskViewModel.selectedPriority = nil
                        }
                    )
                }

                // Tag filter chips
                ForEach(Array(taskViewModel.selectedTags), id: \.id) { tag in
                    FilterChip(
                        label: tag.name ?? "Tag",
                        color: tag.color,
                        onRemove: {
                            taskViewModel.selectedTags.remove(tag)
                        }
                    )
                }

                // Clear all button
                if hasActiveFilters {
                    Button(action: {
                        taskViewModel.clearFilters()
                    }) {
                        Text("Clear All")
                            .font(.caption.weight(.medium))
                            .foregroundColor(AppColors.primaryTeal)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(AppColors.secondaryBackground(for: colorScheme))
    }

    // MARK: - Task List Content

    private var taskListContent: some View {
        List {
            ForEach(taskViewModel.displayedTasks, id: \.id) { task in
                TaskRowView(task: task)
                    .listRowBackground(AppColors.cardBackground(for: colorScheme))
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteTask(task)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            toggleCompletion(task)
                        } label: {
                            Label(
                                task.isCompleted ? "Undo" : "Complete",
                                systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark"
                            )
                        }
                        .tint(AppColors.completed)
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack {
            Spacer()
            EmptyStateView(
                icon: emptyStateIcon,
                title: emptyStateTitle,
                message: emptyStateMessage,
                color: AppColors.softBlue
            )
            Spacer()
        }
    }

    private var emptyStateIcon: String {
        if hasActiveFilters {
            return "magnifyingglass"
        }
        return "checkmark.circle"
    }

    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return "No results found"
        }
        if hasActiveFilters {
            return "No matching tasks"
        }
        return "No tasks yet"
    }

    private var emptyStateMessage: String {
        if !searchText.isEmpty {
            return "Try a different search term."
        }
        if hasActiveFilters {
            return "Try adjusting your filters."
        }
        return "Tap the + button to add your first task."
    }

    // MARK: - Actions

    private func deleteTask(_ task: TaskEntity) {
        withAnimation {
            taskViewModel.deleteTask(task)
        }
    }

    private func toggleCompletion(_ task: TaskEntity) {
        // Haptic feedback
        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.impactOccurred()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            taskViewModel.toggleCompletion(for: task)
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    var color: Color = AppColors.primaryTeal
    let onRemove: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption.weight(.medium))

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .foregroundColor(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .cornerRadius(16)
    }
}

// MARK: - Filter Sheet View

struct FilterSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var taskViewModel: TaskViewModel
    @EnvironmentObject private var tagViewModel: TagViewModel

    var body: some View {
        NavigationStack {
            Form {
                // Status filter
                Section("Status") {
                    ForEach(TaskFilter.allCases) { filter in
                        Button(action: {
                            taskViewModel.currentFilter = filter
                        }) {
                            HStack {
                                Label(filter.rawValue, systemImage: filter.icon)
                                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                                Spacer()
                                if taskViewModel.currentFilter == filter {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AppColors.primaryTeal)
                                }
                            }
                        }
                    }
                }

                // Priority filter
                Section("Priority") {
                    Button(action: {
                        taskViewModel.selectedPriority = nil
                    }) {
                        HStack {
                            Text("Any")
                                .foregroundColor(AppColors.textPrimary(for: colorScheme))
                            Spacer()
                            if taskViewModel.selectedPriority == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColors.primaryTeal)
                            }
                        }
                    }

                    ForEach(TaskPriority.allCases) { priority in
                        Button(action: {
                            taskViewModel.selectedPriority = priority
                        }) {
                            HStack {
                                Label(priority.label, systemImage: priority.icon)
                                    .foregroundColor(priority.color)
                                Spacer()
                                if taskViewModel.selectedPriority == priority {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AppColors.primaryTeal)
                                }
                            }
                        }
                    }
                }

                // Tag filter
                Section("Tags") {
                    ForEach(tagViewModel.tags, id: \.id) { tag in
                        Button(action: {
                            if taskViewModel.selectedTags.contains(tag) {
                                taskViewModel.selectedTags.remove(tag)
                            } else {
                                taskViewModel.selectedTags.insert(tag)
                            }
                        }) {
                            HStack {
                                Circle()
                                    .fill(tag.color)
                                    .frame(width: 12, height: 12)
                                Text(tag.name ?? "Tag")
                                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                                Spacer()
                                if taskViewModel.selectedTags.contains(tag) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AppColors.primaryTeal)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear") {
                        taskViewModel.clearFilters()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Sort Sheet View

struct SortSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var taskViewModel: TaskViewModel

    var body: some View {
        NavigationStack {
            List {
                ForEach(TaskSort.allCases) { sort in
                    Button(action: {
                        taskViewModel.currentSort = sort
                        dismiss()
                    }) {
                        HStack {
                            Text(sort.rawValue)
                                .foregroundColor(AppColors.textPrimary(for: colorScheme))
                            Spacer()
                            if taskViewModel.currentSort == sort {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColors.primaryTeal)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sort By")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.height(250)])
    }
}

// MARK: - Preview

#Preview {
    TaskListView()
        .environmentObject(TaskViewModel(context: PersistenceController.preview.container.viewContext))
        .environmentObject(TagViewModel(context: PersistenceController.preview.container.viewContext))
}
