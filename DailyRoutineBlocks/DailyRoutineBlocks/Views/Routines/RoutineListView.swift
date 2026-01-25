//
//  RoutineListView.swift
//  DailyRoutineBlocks
//

import SwiftUI
import SwiftData

struct RoutineListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Routine.name) private var routines: [Routine]

    @StateObject private var viewModel = RoutineViewModel()
    @State private var isShowingNewRoutine = false
    @State private var selectedRoutineForApply: Routine?
    @State private var applyToDate: Date = Date()
    @State private var isShowingApplySheet = false

    var body: some View {
        NavigationStack {
            Group {
                if routines.isEmpty {
                    EmptyRoutinesView(onCreateTapped: { isShowingNewRoutine = true })
                } else {
                    List {
                        ForEach(routines) { routine in
                            NavigationLink(destination: RoutineDetailView(routine: routine)) {
                                RoutineRowView(routine: routine)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deleteRoutine(routine)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    selectedRoutineForApply = routine
                                    applyToDate = Date()
                                    isShowingApplySheet = true
                                } label: {
                                    Label("Apply", systemImage: "calendar.badge.plus")
                                }
                                .tint(.blue)
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    duplicateRoutine(routine)
                                } label: {
                                    Label("Duplicate", systemImage: "doc.on.doc")
                                }
                                .tint(.orange)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Routines")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { isShowingNewRoutine = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
            .sheet(isPresented: $isShowingNewRoutine) {
                NewRoutineSheet()
            }
            .sheet(isPresented: $isShowingApplySheet) {
                if let routine = selectedRoutineForApply {
                    ApplyRoutineSheet(
                        routine: routine,
                        selectedDate: $applyToDate,
                        onApply: {
                            applyRoutine(routine, toDate: applyToDate)
                        }
                    )
                }
            }
        }
    }

    private func deleteRoutine(_ routine: Routine) {
        modelContext.delete(routine)
        try? modelContext.save()
    }

    private func duplicateRoutine(_ routine: Routine) {
        let newBlocks = routine.blocks.map { block in
            RoutineBlock(
                title: block.title,
                startMinutesFromMidnight: block.startMinutesFromMidnight,
                durationMinutes: block.durationMinutes,
                colorHex: block.colorHex,
                icon: block.icon,
                notes: block.notes
            )
        }

        let newRoutine = Routine(
            name: "\(routine.name) (Copy)",
            blocks: newBlocks
        )

        modelContext.insert(newRoutine)
        try? modelContext.save()
    }

    private func applyRoutine(_ routine: Routine, toDate date: Date) {
        let timeBlocks = routine.applyToDate(date)
        for block in timeBlocks {
            modelContext.insert(block)
        }
        try? modelContext.save()
    }
}

// MARK: - Routine Row View

struct RoutineRowView: View {
    let routine: Routine

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(routine.name)
                .font(.headline)

            HStack(spacing: 16) {
                Label("\(routine.blocks.count) blocks", systemImage: "square.stack")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label(routine.formattedTotalDuration, systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Color preview
            HStack(spacing: 4) {
                ForEach(routine.sortedBlocks.prefix(6)) { block in
                    Circle()
                        .fill(block.color)
                        .frame(width: 12, height: 12)
                }

                if routine.blocks.count > 6 {
                    Text("+\(routine.blocks.count - 6)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Empty Routines View

struct EmptyRoutinesView: View {
    let onCreateTapped: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No Routines", systemImage: "repeat")
        } description: {
            Text("Create routines to quickly fill your day with preset time blocks")
        } actions: {
            Button(action: onCreateTapped) {
                Text("Create Routine")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Apply Routine Sheet

struct ApplyRoutineSheet: View {
    let routine: Routine
    @Binding var selectedDate: Date
    let onApply: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Routine summary
                VStack(spacing: 8) {
                    Text(routine.name)
                        .font(.title2.weight(.semibold))

                    Text("\(routine.blocks.count) blocks \u{2022} \(routine.formattedTotalDuration)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top)

                // Date picker
                DatePicker(
                    "Apply to",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding(.horizontal)

                Spacer()

                // Apply button
                Button(action: {
                    onApply()
                    dismiss()
                }) {
                    Text("Apply Routine")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Apply Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - New Routine Sheet

struct NewRoutineSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @FocusState private var isNameFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Routine name", text: $name)
                        .focused($isNameFocused)
                } header: {
                    Text("Name")
                } footer: {
                    Text("You can add blocks after creating the routine")
                }
            }
            .navigationTitle("New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createRoutine()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                isNameFocused = true
            }
        }
    }

    private func createRoutine() {
        let routine = Routine(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
        modelContext.insert(routine)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    RoutineListView()
        .modelContainer(for: [Routine.self, RoutineBlock.self, TimeBlock.self], inMemory: true)
}
