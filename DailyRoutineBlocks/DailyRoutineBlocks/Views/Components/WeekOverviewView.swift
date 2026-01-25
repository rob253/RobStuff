//
//  WeekOverviewView.swift
//  DailyRoutineBlocks
//

import SwiftUI
import SwiftData

struct WeekOverviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allBlocks: [TimeBlock]

    @Binding var selectedDate: Date
    let onDaySelected: (Date) -> Void

    private var weekDates: [Date] {
        selectedDate.datesOfWeek()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with month/year
            HStack {
                Text(headerText)
                    .font(.headline)

                Spacer()

                Button("Today") {
                    withAnimation {
                        selectedDate = Date()
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.blue)
                .opacity(selectedDate.isToday ? 0 : 1)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Week navigation
            HStack {
                Button {
                    withAnimation {
                        selectedDate = selectedDate.adding(days: -7)
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.caption.weight(.semibold))
                }

                Spacer()

                // Week days
                HStack(spacing: 4) {
                    ForEach(weekDates, id: \.self) { date in
                        WeekDayView(
                            date: date,
                            isSelected: date.isSameDay(as: selectedDate),
                            blocks: blocksForDate(date)
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedDate = date
                            }
                            onDaySelected(date)
                        }
                    }
                }

                Spacer()

                Button {
                    withAnimation {
                        selectedDate = selectedDate.adding(days: 7)
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 12)

            Divider()
        }
        .background(Color(.systemBackground))
    }

    private var headerText: String {
        let startDate = weekDates.first ?? selectedDate
        let endDate = weekDates.last ?? selectedDate

        if startDate.monthName == endDate.monthName {
            return "\(startDate.monthName) \(startDate.year)"
        } else if startDate.year == endDate.year {
            return "\(startDate.shortMonthName) - \(endDate.shortMonthName) \(startDate.year)"
        } else {
            return "\(startDate.shortMonthName) \(startDate.year) - \(endDate.shortMonthName) \(endDate.year)"
        }
    }

    private func blocksForDate(_ date: Date) -> [TimeBlock] {
        allBlocks.filter { $0.startTime.isSameDay(as: date) }
            .sorted { $0.startTime < $1.startTime }
    }
}

// MARK: - Week Day View

struct WeekDayView: View {
    let date: Date
    let isSelected: Bool
    let blocks: [TimeBlock]

    private var isToday: Bool {
        date.isToday
    }

    var body: some View {
        VStack(spacing: 4) {
            // Day name
            Text(date.shortDayOfWeek.prefix(1))
                .font(.caption2)
                .foregroundStyle(.secondary)

            // Day number
            ZStack {
                if isSelected {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 32, height: 32)
                } else if isToday {
                    Circle()
                        .strokeBorder(Color.blue, lineWidth: 1.5)
                        .frame(width: 32, height: 32)
                }

                Text("\(date.dayNumber)")
                    .font(.subheadline.weight(isSelected || isToday ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .white : (isToday ? .blue : .primary))
            }

            // Block indicators
            HStack(spacing: 2) {
                ForEach(blocks.prefix(3)) { block in
                    Circle()
                        .fill(block.color)
                        .frame(width: 6, height: 6)
                }

                if blocks.count > 3 {
                    Text("+")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 8)
        }
        .frame(width: 44)
        .padding(.vertical, 4)
    }
}

// MARK: - Mini Timeline View (for Week Overview expansion)

struct MiniTimelineView: View {
    let blocks: [TimeBlock]
    let startHour: Int
    let endHour: Int
    let height: CGFloat

    private var hourHeight: CGFloat {
        height / CGFloat(endHour - startHour)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.tertiarySystemBackground))

                // Blocks
                ForEach(blocks) { block in
                    let yOffset = yPosition(for: block.startTime)
                    let blockHeight = self.blockHeight(for: block)

                    CompactTimeBlockView(block: block, height: blockHeight)
                        .offset(y: yOffset)
                        .padding(.horizontal, 2)
                }
            }
        }
        .frame(height: height)
    }

    private func yPosition(for date: Date) -> CGFloat {
        let minutesFromStart = date.minutesFromMidnight - (startHour * 60)
        return CGFloat(minutesFromStart) * (hourHeight / 60)
    }

    private func blockHeight(for block: TimeBlock) -> CGFloat {
        let duration = CGFloat(block.durationMinutes)
        return max(duration * (hourHeight / 60), 4) // Minimum height of 4
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selectedDate = Date()

    VStack {
        WeekOverviewView(
            selectedDate: $selectedDate,
            onDaySelected: { _ in }
        )

        Spacer()
    }
    .modelContainer(for: TimeBlock.self, inMemory: true)
}
