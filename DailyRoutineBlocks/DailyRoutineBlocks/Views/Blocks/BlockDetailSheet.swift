//
//  BlockDetailSheet.swift
//  DailyRoutineBlocks
//

import SwiftUI
import SwiftData

struct BlockDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var block: TimeBlock

    @State private var title: String
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var selectedColor: BlockColor
    @State private var selectedIcon: String?
    @State private var notes: String
    @State private var notificationEnabled: Bool
    @State private var reminderMinutes: Int
    @State private var isCompleted: Bool

    @State private var isShowingColorPicker = false
    @State private var isShowingIconPicker = false
    @State private var isShowingDeleteConfirmation = false
    @State private var isEditing = false

    init(block: TimeBlock) {
        self.block = block
        _title = State(initialValue: block.title)
        _startTime = State(initialValue: block.startTime)
        _endTime = State(initialValue: block.endTime)
        _selectedColor = State(initialValue: BlockColor.allCases.first { $0.hex == block.colorHex } ?? .blue)
        _selectedIcon = State(initialValue: block.icon)
        _notes = State(initialValue: block.notes ?? "")
        _notificationEnabled = State(initialValue: block.notificationEnabled)
        _reminderMinutes = State(initialValue: block.reminderMinutesBefore ?? AppConstants.defaultReminderMinutes)
        _isCompleted = State(initialValue: block.isCompleted)
    }

    private var hasChanges: Bool {
        title != block.title ||
        startTime != block.startTime ||
        endTime != block.endTime ||
        selectedColor.hex != block.colorHex ||
        selectedIcon != block.icon ||
        notes != (block.notes ?? "") ||
        notificationEnabled != block.notificationEnabled ||
        reminderMinutes != (block.reminderMinutesBefore ?? AppConstants.defaultReminderMinutes) ||
        isCompleted != block.isCompleted
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        endTime > startTime
    }

    var body: some View {
        NavigationStack {
            Form {
                // Status Section
                Section {
                    Toggle("Completed", isOn: $isCompleted)
                }

                // Title Section
                Section {
                    if isEditing {
                        TextField("Block title", text: $title)
                            .font(.headline)
                    } else {
                        Text(title)
                            .font(.headline)
                            .strikethrough(isCompleted)
                            .foregroundStyle(isCompleted ? .secondary : .primary)
                    }
                } header: {
                    Text("Title")
                }

                // Time Section
                Section {
                    if isEditing {
                        DatePicker(
                            "Start",
                            selection: $startTime,
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: startTime) { _, newValue in
                            if endTime <= newValue {
                                endTime = newValue.adding(minutes: TimelineConstants.minimumBlockDuration)
                            }
                        }

                        DatePicker(
                            "End",
                            selection: $endTime,
                            in: startTime.adding(minutes: TimelineConstants.minimumBlockDuration)...,
                            displayedComponents: .hourAndMinute
                        )
                    } else {
                        HStack {
                            Text("Time")
                            Spacer()
                            Text(block.formattedTimeRange)
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack {
                        Text("Duration")
                        Spacer()
                        Text(formattedDuration)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Date")
                        Spacer()
                        Text(block.startTime.formattedDate)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Time")
                }

                // Appearance Section
                Section {
                    if isEditing {
                        Button(action: { isShowingColorPicker = true }) {
                            HStack {
                                Text("Color")
                                Spacer()
                                Circle()
                                    .fill(selectedColor.color)
                                    .frame(width: 24, height: 24)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .foregroundStyle(.primary)

                        Button(action: { isShowingIconPicker = true }) {
                            HStack {
                                Text("Icon")
                                Spacer()
                                if let icon = selectedIcon {
                                    Image(systemName: icon)
                                        .foregroundStyle(selectedColor.color)
                                } else {
                                    Text("None")
                                        .foregroundStyle(.secondary)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .foregroundStyle(.primary)
                    } else {
                        HStack {
                            Text("Color")
                            Spacer()
                            Circle()
                                .fill(selectedColor.color)
                                .frame(width: 24, height: 24)
                        }

                        HStack {
                            Text("Icon")
                            Spacer()
                            if let icon = selectedIcon {
                                Image(systemName: icon)
                                    .foregroundStyle(selectedColor.color)
                            } else {
                                Text("None")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Appearance")
                }

                // Notes Section
                if isEditing || !notes.isEmpty {
                    Section {
                        if isEditing {
                            TextField("Add notes...", text: $notes, axis: .vertical)
                                .lineLimit(3...6)
                        } else {
                            Text(notes.isEmpty ? "No notes" : notes)
                                .foregroundStyle(notes.isEmpty ? .secondary : .primary)
                        }
                    } header: {
                        Text("Notes")
                    }
                }

                // Notification Section
                Section {
                    if isEditing {
                        Toggle("Reminder", isOn: $notificationEnabled)

                        if notificationEnabled {
                            Picker("Remind me", selection: $reminderMinutes) {
                                ForEach([5, 10, 15, 30, 45, 60], id: \.self) { minutes in
                                    Text(formatReminderTime(minutes)).tag(minutes)
                                }
                            }
                        }
                    } else {
                        HStack {
                            Text("Reminder")
                            Spacer()
                            if notificationEnabled {
                                Text(formatReminderTime(reminderMinutes))
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Off")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Notifications")
                }

                // Delete Section
                Section {
                    Button(role: .destructive) {
                        isShowingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete Block")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Block" : "Block Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if isEditing {
                        Button("Cancel") {
                            resetChanges()
                            isEditing = false
                        }
                    } else {
                        Button("Done") {
                            if hasChanges {
                                saveChanges()
                            }
                            dismiss()
                        }
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    if isEditing {
                        Button("Save") {
                            saveChanges()
                            isEditing = false
                        }
                        .disabled(!isValid)
                        .fontWeight(.semibold)
                    } else {
                        Button("Edit") {
                            isEditing = true
                        }
                    }
                }
            }
            .sheet(isPresented: $isShowingColorPicker) {
                ColorPickerView(selectedColor: $selectedColor)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $isShowingIconPicker) {
                IconPickerView(selectedIcon: $selectedIcon)
                    .presentationDetents([.large])
            }
            .confirmationDialog(
                "Delete Block",
                isPresented: $isShowingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    deleteBlock()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete '\(block.title)'? This action cannot be undone.")
            }
        }
    }

    private var formattedDuration: String {
        let minutes = Calendar.current.dateComponents([.minute], from: startTime, to: endTime).minute ?? 0
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if hours > 0 && remainingMinutes > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(remainingMinutes)m"
        }
    }

    private func formatReminderTime(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) minutes before"
        } else {
            return "1 hour before"
        }
    }

    private func saveChanges() {
        block.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        block.startTime = startTime
        block.endTime = endTime
        block.colorHex = selectedColor.hex
        block.icon = selectedIcon
        block.notes = notes.isEmpty ? nil : notes
        block.notificationEnabled = notificationEnabled
        block.reminderMinutesBefore = notificationEnabled ? reminderMinutes : nil
        block.isCompleted = isCompleted
        block.updatedAt = Date()

        do {
            try modelContext.save()
        } catch {
            print("Failed to save block changes: \(error)")
        }
    }

    private func resetChanges() {
        title = block.title
        startTime = block.startTime
        endTime = block.endTime
        selectedColor = BlockColor.allCases.first { $0.hex == block.colorHex } ?? .blue
        selectedIcon = block.icon
        notes = block.notes ?? ""
        notificationEnabled = block.notificationEnabled
        reminderMinutes = block.reminderMinutesBefore ?? AppConstants.defaultReminderMinutes
        isCompleted = block.isCompleted
    }

    private func deleteBlock() {
        modelContext.delete(block)
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete block: \(error)")
        }
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    let block = TimeBlock.sample(title: "Team Meeting")
    block.icon = "video"
    block.notes = "Discuss Q4 planning and roadmap priorities"

    return BlockDetailSheet(block: block)
        .modelContainer(for: TimeBlock.self, inMemory: true)
}
