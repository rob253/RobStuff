import SwiftUI

/// Tag management view for creating, editing, and deleting tags
struct TagManagementView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var tagViewModel: TagViewModel

    // MARK: - State

    @State private var showingAddTag = false
    @State private var tagToEdit: TagEntity?
    @State private var showingDeleteConfirmation = false
    @State private var tagToDelete: TagEntity?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // Tags list
                ForEach(tagViewModel.tags, id: \.id) { tag in
                    TagRow(tag: tag)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            tagToEdit = tag
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                tagToDelete = tag
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                tagToEdit = tag
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(AppColors.softBlue)
                        }
                }

                // Add new tag button
                Button(action: { showingAddTag = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AppColors.primaryTeal)
                        Text("Add New Tag")
                            .foregroundColor(AppColors.primaryTeal)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Manage Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddTag) {
                TagEditorView(mode: .add)
            }
            .sheet(item: $tagToEdit) { tag in
                TagEditorView(mode: .edit(tag))
            }
            .confirmationDialog(
                "Delete Tag",
                isPresented: $showingDeleteConfirmation,
                presenting: tagToDelete
            ) { tag in
                Button("Delete", role: .destructive) {
                    tagViewModel.deleteTag(tag)
                }
                Button("Cancel", role: .cancel) {}
            } message: { tag in
                Text("Are you sure you want to delete \"\(tag.name ?? "this tag")\"? This will remove the tag from all tasks.")
            }
        }
    }
}

// MARK: - Tag Row

struct TagRow: View {
    let tag: TagEntity

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            // Color indicator
            Circle()
                .fill(tag.color)
                .frame(width: 24, height: 24)

            // Tag name
            VStack(alignment: .leading, spacing: 2) {
                Text(tag.name ?? "Unnamed")
                    .font(.body)
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))

                Text("\(tag.totalTaskCount) task\(tag.totalTaskCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary(for: colorScheme))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary(for: colorScheme))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Tag Editor View

struct TagEditorView: View {
    // MARK: - Mode

    enum Mode: Identifiable {
        case add
        case edit(TagEntity)

        var id: String {
            switch self {
            case .add: return "add"
            case .edit(let tag): return tag.id?.uuidString ?? "edit"
            }
        }
    }

    let mode: Mode

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var tagViewModel: TagViewModel

    // MARK: - State

    @State private var name: String
    @State private var selectedColorIndex: Int
    @State private var showingError = false
    @State private var errorMessage = ""

    // MARK: - Initialization

    init(mode: Mode) {
        self.mode = mode

        switch mode {
        case .add:
            _name = State(initialValue: "")
            _selectedColorIndex = State(initialValue: 0)
        case .edit(let tag):
            _name = State(initialValue: tag.name ?? "")
            let index = AppColors.tagPaletteHex.firstIndex(of: tag.colorHex ?? "#5E9EA0") ?? 0
            _selectedColorIndex = State(initialValue: index)
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Name section
                Section("Tag Name") {
                    TextField("Enter tag name", text: $name)
                        .autocapitalization(.words)
                }

                // Color section
                Section("Tag Color") {
                    colorPicker
                }

                // Preview section
                Section("Preview") {
                    HStack {
                        Spacer()
                        previewTag
                        Spacer()
                    }
                    .listRowBackground(AppColors.secondaryBackground(for: colorScheme))
                }
            }
            .navigationTitle(isEditing ? "Edit Tag" : "New Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveTag()
                    }
                    .font(.headline)
                    .disabled(name.isEmpty)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Color Picker

    private var colorPicker: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
            ForEach(Array(AppColors.tagPalette.enumerated()), id: \.offset) { index, color in
                Circle()
                    .fill(color)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .opacity(selectedColorIndex == index ? 1 : 0)
                    )
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.white)
                            .opacity(selectedColorIndex == index ? 1 : 0)
                    )
                    .shadow(color: color.opacity(0.4), radius: selectedColorIndex == index ? 4 : 0)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            selectedColorIndex = index
                        }
                    }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Preview Tag

    private var previewTag: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(selectedColor)
                .frame(width: 10, height: 10)
            Text(name.isEmpty ? "Tag Name" : name)
                .font(.subheadline.weight(.medium))
        }
        .foregroundColor(selectedColor)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(selectedColor.opacity(0.15))
        .cornerRadius(16)
    }

    // MARK: - Computed Properties

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var selectedColor: Color {
        AppColors.tagPalette[selectedColorIndex]
    }

    private var selectedColorHex: String {
        AppColors.tagPaletteHex[selectedColorIndex]
    }

    // MARK: - Actions

    private func saveTag() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        switch mode {
        case .add:
            if tagViewModel.createTag(name: trimmedName, colorHex: selectedColorHex) {
                dismiss()
            } else {
                errorMessage = tagViewModel.errorMessage ?? "Failed to create tag"
                showingError = true
                tagViewModel.clearError()
            }

        case .edit(let tag):
            tagViewModel.updateTag(tag, name: trimmedName, colorHex: selectedColorHex)
            if let error = tagViewModel.errorMessage {
                errorMessage = error
                showingError = true
                tagViewModel.clearError()
            } else {
                dismiss()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TagManagementView()
        .environmentObject(TagViewModel(context: PersistenceController.preview.container.viewContext))
}
