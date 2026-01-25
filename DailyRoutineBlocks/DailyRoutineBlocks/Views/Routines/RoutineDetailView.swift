//
//  RoutineDetailView.swift
//  DailyRoutineBlocks
//

import SwiftUI
import SwiftData

struct RoutineDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var routine: Routine

    @State private var isEditing = false
    @State private var editedName: String = ""
    @State private var isShowingAddBlock = false
    @State private var isShowingDeleteConfirmation = false
    @State private var selectedBlock: RoutineBlock?

    var body: some View {
        List {
            // Header Section
            Section {
                if isEditing {
                    TextField("Routine name", text: $editedName)
                        .font(.headline)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(routine.name)
                            .font(.title2.weight(.semibold))

                        HStack(spacing: 16) {
                            Label("\(routine.blocks.count) blocks", systemImage: "square.stack")
                            Label(routine.formattedTotalDuration, systemImage: "clock")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            // Blocks Section
            Section {
                if routine.blocks.isEmpty {
                    ContentUnavailableView {
                        Label("No Blocks", systemImage: "square.dashed")
                    } description: {
                        Text("Add blocks to build your routine")
                    } actions: {
                        Button("Add Block") {
                            isShowingAddBlock = true
                        }
                    }
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(routine.sortedBlocks) { block in
                        RoutineBlockRowView(block: block)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedBlock = block
                            }
                    }
                    .onDelete(perform: deleteBlocks)
                }
            } header: {
                HStack {
                    Text("Blocks")
                    Spacer()
                    Button(action: { isShowingAddBlock = true }) {
                        Image(systemName: "plus")
                    }
                }
            }

            // Timeline Preview Section
            if !routine.blocks.isEmpty {
                Section {
                    RoutineTimelinePreview(blocks: routine.sortedBlocks)
                        .frame(height: 200)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                } header: {
                    Text("Preview")
                }
            }

            // Delete Section
            Section {
                Button(role: .destructive) {
                    isShowingDeleteConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Delete Routine")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Routine Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if isEditing {
                    Button("Done") {
                        saveChanges()
                        isEditing = false
                    }
                    .fontWeight(.semibold)
                } else {
                    Button("Edit") {
                        editedName = routine.name
                        isEditing = true
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingAddBlock) {
            AddRoutineBlockSheet(routine: routine)
        }
        .sheet(item: $selectedBlock) { block in
            EditRoutineBlockSheet(routine: routine, block: block)
        }
        .confirmationDialog(
            "Delete Routine",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteRoutine()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete '\(routine.name)'? This cannot be undone.")
        }
    }

    private func saveChanges() {
        routine.name = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        routine.updatedAt = Date()
        try? modelContext.save()
    }

    private func deleteBlocks(at offsets: IndexSet) {
        let sortedBlocks = routine.sortedBlocks
        for index in offsets {
            let block = sortedBlocks[index]
            routine.blocks.removeAll { $0.id == block.id }
        }
        routine.updatedAt = Date()
        try? modelContext.save()
    }

    private func deleteRoutine() {
        modelContext.delete(routine)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Routine Block Row View

struct RoutineBlockRowView: View {
    let block: RoutineBlock

    var body: some View {
        HStack(spacing: 12) {
            // Color indicator
            RoundedRectangle(cornerRadius: 4)
                .fill(block.color)
                .frame(width: 4, height: 44)

            // Icon
            if let iconName = block.icon {
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundStyle(block.color)
                    .frame(width: 32)
            }

            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(block.title)
                    .font(.headline)

                Text(block.formattedTimeRange)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(block.formattedDuration)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Routine Timeline Preview

struct RoutineTimelinePreview: View {
    let blocks: [RoutineBlock]

    private var startHour: Int {
        guard let firstBlock = blocks.first else { return 6 }
        return max(0, firstBlock.startMinutesFromMidnight / 60 - 1)
    }

    private var endHour: Int {
        guard let lastBlock = blocks.last else { return 23 }
        return min(24, lastBlock.endMinutesFromMidnight / 60 + 1)
    }

    private var hourHeight: CGFloat {
        200 / CGFloat(max(1, endHour - startHour))
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .top, spacing: 0) {
                // Hour labels
                VStack(spacing: 0) {
                    ForEach(startHour..<endHour, id: \.self) { hour in
                        Text(formatHour(hour))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(height: hourHeight, alignment: .top)
                    }
                }
                .frame(width: 50)

                // Timeline
                ZStack(alignment: .topLeading) {
                    // Grid lines
                    VStack(spacing: 0) {
                        ForEach(startHour..<endHour, id: \.self) { _ in
                            VStack(spacing: 0) {
                                Rectangle()
                                    .fill(Color.gridLine)
                                    .frame(height: 1)
                                Spacer()
                            }
                            .frame(height: hourHeight)
                        }
                    }

                    // Blocks
                    ForEach(blocks) { block in
                        let yOffset = yPosition(for: block.startMinutesFromMidnight)
                        let blockHeight = CGFloat(block.durationMinutes) / 60 * hourHeight

                        HStack(spacing: 6) {
                            if let icon = block.icon {
                                Image(systemName: icon)
                                    .font(.caption2)
                            }
                            Text(block.title)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .foregroundStyle(block.color.contrastingTextColor)
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: max(blockHeight, 20))
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(block.color)
                        )
                        .offset(y: yOffset)
                        .padding(.horizontal, 4)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    private func yPosition(for minutesFromMidnight: Int) -> CGFloat {
        let minutesFromStart = minutesFromMidnight - (startHour * 60)
        return CGFloat(minutesFromStart) / 60 * hourHeight
    }

    private func formatHour(_ hour: Int) -> String {
        if hour == 0 { return "12a" }
        if hour < 12 { return "\(hour)a" }
        if hour == 12 { return "12p" }
        return "\(hour - 12)p"
    }
}

// MARK: - Add Routine Block Sheet

struct AddRoutineBlockSheet: View {
    let routine: Routine

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var startHour = 9
    @State private var startMinute = 0
    @State private var durationMinutes = 60
    @State private var selectedColor: BlockColor = .blue
    @State private var selectedIcon: String?

    @State private var isShowingColorPicker = false
    @State private var isShowingIconPicker = false

    @FocusState private var isTitleFocused: Bool

    private var startMinutesFromMidnight: Int {
        startHour * 60 + startMinute
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Block title", text: $title)
                        .focused($isTitleFocused)
                } header: {
                    Text("Title")
                }

                Section {
                    Picker("Start Hour", selection: $startHour) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }

                    Picker("Start Minute", selection: $startMinute) {
                        ForEach([0, 15, 30, 45], id: \.self) { minute in
                            Text(String(format: ":%02d", minute)).tag(minute)
                        }
                    }

                    Picker("Duration", selection: $durationMinutes) {
                        ForEach([15, 30, 45, 60, 90, 120, 180, 240], id: \.self) { minutes in
                            Text(formatDuration(minutes)).tag(minutes)
                        }
                    }
                } header: {
                    Text("Time")
                }

                Section {
                    Button(action: { isShowingColorPicker = true }) {
                        HStack {
                            Text("Color")
                            Spacer()
                            Circle()
                                .fill(selectedColor.color)
                                .frame(width: 24, height: 24)
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
                        }
                    }
                    .foregroundStyle(.primary)
                } header: {
                    Text("Appearance")
                }
            }
            .navigationTitle("Add Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addBlock()
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

    private func formatHour(_ hour: Int) -> String {
        if hour == 0 { return "12 AM" }
        if hour < 12 { return "\(hour) AM" }
        if hour == 12 { return "12 PM" }
        return "\(hour - 12) PM"
    }

    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours) hour\(hours > 1 ? "s" : "")"
        } else {
            return "\(mins) minutes"
        }
    }

    private func addBlock() {
        let block = RoutineBlock(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            startMinutesFromMidnight: startMinutesFromMidnight,
            durationMinutes: durationMinutes,
            colorHex: selectedColor.hex,
            icon: selectedIcon
        )

        routine.blocks.append(block)
        routine.updatedAt = Date()
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Edit Routine Block Sheet

struct EditRoutineBlockSheet: View {
    let routine: Routine
    @Bindable var block: RoutineBlock

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var startHour: Int
    @State private var startMinute: Int
    @State private var durationMinutes: Int
    @State private var selectedColor: BlockColor
    @State private var selectedIcon: String?

    @State private var isShowingColorPicker = false
    @State private var isShowingIconPicker = false
    @State private var isShowingDeleteConfirmation = false

    init(routine: Routine, block: RoutineBlock) {
        self.routine = routine
        self.block = block
        _title = State(initialValue: block.title)
        _startHour = State(initialValue: block.startMinutesFromMidnight / 60)
        _startMinute = State(initialValue: block.startMinutesFromMidnight % 60)
        _durationMinutes = State(initialValue: block.durationMinutes)
        _selectedColor = State(initialValue: BlockColor.allCases.first { $0.hex == block.colorHex } ?? .blue)
        _selectedIcon = State(initialValue: block.icon)
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Block title", text: $title)
                } header: {
                    Text("Title")
                }

                Section {
                    Picker("Start Hour", selection: $startHour) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }

                    Picker("Start Minute", selection: $startMinute) {
                        ForEach([0, 15, 30, 45], id: \.self) { minute in
                            Text(String(format: ":%02d", minute)).tag(minute)
                        }
                    }

                    Picker("Duration", selection: $durationMinutes) {
                        ForEach([15, 30, 45, 60, 90, 120, 180, 240], id: \.self) { minutes in
                            Text(formatDuration(minutes)).tag(minutes)
                        }
                    }
                } header: {
                    Text("Time")
                }

                Section {
                    Button(action: { isShowingColorPicker = true }) {
                        HStack {
                            Text("Color")
                            Spacer()
                            Circle()
                                .fill(selectedColor.color)
                                .frame(width: 24, height: 24)
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
                        }
                    }
                    .foregroundStyle(.primary)
                } header: {
                    Text("Appearance")
                }

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
            .navigationTitle("Edit Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
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
            }
        }
    }

    private func formatHour(_ hour: Int) -> String {
        if hour == 0 { return "12 AM" }
        if hour < 12 { return "\(hour) AM" }
        if hour == 12 { return "12 PM" }
        return "\(hour - 12) PM"
    }

    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours) hour\(hours > 1 ? "s" : "")"
        } else {
            return "\(mins) minutes"
        }
    }

    private func saveChanges() {
        block.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        block.startMinutesFromMidnight = startHour * 60 + startMinute
        block.durationMinutes = durationMinutes
        block.colorHex = selectedColor.hex
        block.icon = selectedIcon
        routine.updatedAt = Date()
        try? modelContext.save()
        dismiss()
    }

    private func deleteBlock() {
        routine.blocks.removeAll { $0.id == block.id }
        routine.updatedAt = Date()
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    let routine = Routine.sample()
    return NavigationStack {
        RoutineDetailView(routine: routine)
    }
    .modelContainer(for: [Routine.self, RoutineBlock.self], inMemory: true)
}
