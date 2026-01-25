//
//  BlockCreationSheet.swift
//  DailyRoutineBlocks
//

import SwiftUI
import SwiftData

struct BlockCreationSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let initialStartTime: Date
    let selectedDate: Date

    @State private var title: String = ""
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var selectedColor: BlockColor = .blue
    @State private var selectedIcon: String? = nil
    @State private var notes: String = ""
    @State private var notificationEnabled: Bool = false
    @State private var reminderMinutes: Int = AppConstants.defaultReminderMinutes

    @State private var isShowingColorPicker = false
    @State private var isShowingIconPicker = false

    @FocusState private var isTitleFocused: Bool

    init(initialStartTime: Date, selectedDate: Date) {
        self.initialStartTime = initialStartTime
        self.selectedDate = selectedDate

        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: initialStartTime)
        let start = calendar.date(
            bySettingHour: startComponents.hour ?? 9,
            minute: startComponents.minute ?? 0,
            second: 0,
            of: selectedDate
        ) ?? initialStartTime

        _startTime = State(initialValue: start)
        _endTime = State(initialValue: start.adding(minutes: TimelineConstants.defaultBlockDuration))
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        endTime > startTime
    }

    var body: some View {
        NavigationStack {
            Form {
                // Title Section
                Section {
                    TextField("Block title", text: $title)
                        .focused($isTitleFocused)
                        .font(.headline)
                } header: {
                    Text("Title")
                }

                // Time Section
                Section {
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

                    HStack {
                        Text("Duration")
                        Spacer()
                        Text(formattedDuration)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Time")
                }

                // Appearance Section
                Section {
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
                } header: {
                    Text("Appearance")
                }

                // Notes Section
                Section {
                    TextField("Add notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes")
                }

                // Notification Section
                Section {
                    Toggle("Reminder", isOn: $notificationEnabled)

                    if notificationEnabled {
                        Picker("Remind me", selection: $reminderMinutes) {
                            ForEach([5, 10, 15, 30, 45, 60], id: \.self) { minutes in
                                Text(formatReminderTime(minutes)).tag(minutes)
                            }
                        }
                    }
                } header: {
                    Text("Notifications")
                }

                // Preview Section
                Section {
                    BlockPreviewView(
                        title: title.isEmpty ? "Block Title" : title,
                        color: selectedColor.color,
                        icon: selectedIcon,
                        startTime: startTime,
                        endTime: endTime
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                } header: {
                    Text("Preview")
                }
            }
            .navigationTitle("New Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveBlock()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                isTitleFocused = true
            }
            .sheet(isPresented: $isShowingColorPicker) {
                ColorPickerView(selectedColor: $selectedColor)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $isShowingIconPicker) {
                IconPickerView(selectedIcon: $selectedIcon)
                    .presentationDetents([.large])
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

    private func saveBlock() {
        let block = TimeBlock(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            startTime: startTime,
            endTime: endTime,
            colorHex: selectedColor.hex,
            icon: selectedIcon,
            notes: notes.isEmpty ? nil : notes,
            notificationEnabled: notificationEnabled,
            reminderMinutesBefore: notificationEnabled ? reminderMinutes : nil
        )

        modelContext.insert(block)

        do {
            try modelContext.save()
        } catch {
            print("Failed to save block: \(error)")
        }

        dismiss()
    }
}

// MARK: - Block Preview View

struct BlockPreviewView: View {
    let title: String
    let color: Color
    let icon: String?
    let startTime: Date
    let endTime: Date

    var body: some View {
        HStack(spacing: 12) {
            if let iconName = icon {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundStyle(color.contrastingTextColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(color.contrastingTextColor)

                Text(formattedTimeRange)
                    .font(.caption)
                    .foregroundStyle(color.contrastingTextColor.opacity(0.8))
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: TimelineConstants.blockCornerRadius)
                .fill(color)
                .shadow(color: .blockShadow, radius: 4, x: 0, y: 2)
        )
        .padding()
    }

    private var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
}

// MARK: - Preview

#Preview {
    BlockCreationSheet(
        initialStartTime: Date(),
        selectedDate: Date()
    )
    .modelContainer(for: TimeBlock.self, inMemory: true)
}
