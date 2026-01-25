//
//  DayNavigationView.swift
//  DailyRoutineBlocks
//

import SwiftUI

struct DayNavigationView: View {
    @Binding var selectedDate: Date
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onToday: () -> Void

    @State private var isShowingDatePicker = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // Previous day button
                Button(action: onPrevious) {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                // Date display with picker
                Button(action: { isShowingDatePicker = true }) {
                    VStack(spacing: 2) {
                        Text(selectedDate.formattedDate)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        if !selectedDate.isToday && !selectedDate.isYesterday && !selectedDate.isTomorrow {
                            Text(selectedDate.fullFormattedDate)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                // Next day button
                Button(action: onNext) {
                    Image(systemName: "chevron.right")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)

            // Today button (only show if not today)
            if !selectedDate.isToday {
                Button(action: onToday) {
                    Text("Today")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.1))
                        )
                }
                .padding(.bottom, 8)
            }

            Divider()
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $isShowingDatePicker) {
            DatePickerSheet(selectedDate: $selectedDate)
                .presentationDetents([.medium])
        }
    }
}

// MARK: - Date Picker Sheet

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss

    @State private var tempDate: Date

    init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
        self._tempDate = State(initialValue: selectedDate.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Select Date",
                    selection: $tempDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()

                Spacer()
            }
            .navigationTitle("Choose Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        selectedDate = tempDate
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Swipeable Day Container

struct SwipeableDayContainer<Content: View>: View {
    @Binding var selectedDate: Date
    let content: () -> Content

    @State private var dragOffset: CGFloat = 0
    private let swipeThreshold: CGFloat = 50

    var body: some View {
        GeometryReader { geometry in
            content()
                .offset(x: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation.width
                        }
                        .onEnded { value in
                            let width = geometry.size.width
                            if value.translation.width > swipeThreshold {
                                // Swipe right - go to previous day
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    dragOffset = width
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    selectedDate = selectedDate.adding(days: -1)
                                    dragOffset = -width
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        dragOffset = 0
                                    }
                                }
                            } else if value.translation.width < -swipeThreshold {
                                // Swipe left - go to next day
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    dragOffset = -width
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    selectedDate = selectedDate.adding(days: 1)
                                    dragOffset = width
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        dragOffset = 0
                                    }
                                }
                            } else {
                                // Return to center
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    dragOffset = 0
                                }
                            }
                        }
                )
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var date = Date()

    VStack {
        DayNavigationView(
            selectedDate: $date,
            onPrevious: { date = date.adding(days: -1) },
            onNext: { date = date.adding(days: 1) },
            onToday: { date = Date() }
        )

        Spacer()
    }
}
