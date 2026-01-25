//
//  TimelineView.swift
//  DailyRoutineBlocks
//

import SwiftUI
import SwiftData

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = TimelineViewModel()
    @Query private var allBlocks: [TimeBlock]

    @State private var scrollProxy: ScrollViewProxy?
    @State private var hasScrolledToCurrentTime = false

    private var blocksForSelectedDate: [TimeBlock] {
        allBlocks.filter { $0.startTime.isSameDay(as: viewModel.selectedDate) }
            .sorted { $0.startTime < $1.startTime }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DayNavigationView(
                    selectedDate: $viewModel.selectedDate,
                    onPrevious: viewModel.goToPreviousDay,
                    onNext: viewModel.goToNextDay,
                    onToday: viewModel.goToToday
                )

                ScrollViewReader { proxy in
                    ScrollView {
                        ZStack(alignment: .topLeading) {
                            // Hour grid
                            TimelineGridView(
                                startHour: viewModel.startHour,
                                endHour: viewModel.endHour,
                                use24HourFormat: viewModel.use24HourFormat
                            )

                            // Time blocks
                            TimeBlocksContainerView(
                                blocks: blocksForSelectedDate,
                                viewModel: viewModel,
                                onBlockTap: { block in
                                    viewModel.showBlockDetail(for: block)
                                },
                                onTimeSlotTap: { time in
                                    viewModel.showBlockCreation(at: time)
                                }
                            )

                            // Current time indicator
                            if viewModel.isCurrentDaySelected {
                                CurrentTimeIndicatorView(
                                    yPosition: viewModel.currentTimeYPosition,
                                    timeColumnWidth: TimelineConstants.timeColumnWidth
                                )
                            }
                        }
                        .frame(minHeight: CGFloat(viewModel.endHour - viewModel.startHour) * TimelineConstants.hourHeight)
                        .id("timeline")
                    }
                    .onAppear {
                        scrollProxy = proxy
                        viewModel.setModelContext(modelContext)

                        // Scroll to current time on first appear
                        if !hasScrolledToCurrentTime && viewModel.isCurrentDaySelected {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                scrollToCurrentTime()
                                hasScrolledToCurrentTime = true
                            }
                        }
                    }
                    .onChange(of: viewModel.selectedDate) { _, newDate in
                        if newDate.isToday {
                            scrollToCurrentTime()
                        }
                    }
                }
            }
            .navigationTitle("Timeline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { viewModel.showBlockCreation() }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $viewModel.isShowingBlockCreation) {
                BlockCreationSheet(
                    initialStartTime: viewModel.newBlockStartTime,
                    selectedDate: viewModel.selectedDate
                )
            }
            .sheet(isPresented: $viewModel.isShowingBlockDetail) {
                if let block = viewModel.selectedBlock {
                    BlockDetailSheet(block: block)
                }
            }
        }
    }

    private func scrollToCurrentTime() {
        guard let proxy = scrollProxy else { return }

        let currentHour = Date().hour
        let targetHour = max(viewModel.startHour, min(currentHour - 1, viewModel.endHour - 2))

        withAnimation {
            proxy.scrollTo("hour-\(targetHour)", anchor: .top)
        }
    }
}

// MARK: - Timeline Grid View

struct TimelineGridView: View {
    let startHour: Int
    let endHour: Int
    let use24HourFormat: Bool

    var body: some View {
        VStack(spacing: 0) {
            ForEach(startHour..<endHour, id: \.self) { hour in
                HStack(alignment: .top, spacing: 0) {
                    // Hour label
                    Text(formatHour(hour))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: TimelineConstants.timeColumnWidth, alignment: .trailing)
                        .padding(.trailing, 8)
                        .offset(y: -8)

                    // Grid line
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.gridLine)
                            .frame(height: 1)
                        Spacer()
                    }
                }
                .frame(height: TimelineConstants.hourHeight)
                .id("hour-\(hour)")
            }
        }
    }

    private func formatHour(_ hour: Int) -> String {
        if use24HourFormat {
            return String(format: "%02d:00", hour)
        } else {
            if hour == 0 {
                return "12 AM"
            } else if hour < 12 {
                return "\(hour) AM"
            } else if hour == 12 {
                return "12 PM"
            } else {
                return "\(hour - 12) PM"
            }
        }
    }
}

// MARK: - Time Blocks Container

struct TimeBlocksContainerView: View {
    let blocks: [TimeBlock]
    let viewModel: TimelineViewModel
    let onBlockTap: (TimeBlock) -> Void
    let onTimeSlotTap: (Date) -> Void

    var body: some View {
        GeometryReader { geometry in
            let blockWidth = geometry.size.width - TimelineConstants.timeColumnWidth - (TimelineConstants.blockHorizontalPadding * 2)

            ZStack(alignment: .topLeading) {
                // Tap target for empty spaces
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        let time = viewModel.timeFromYPosition(location.y)
                        let snappedTime = viewModel.snapToNearestInterval(time)
                        onTimeSlotTap(snappedTime)
                    }
                    .padding(.leading, TimelineConstants.timeColumnWidth)

                // Render blocks
                ForEach(blocks) { block in
                    TimeBlockView(
                        block: block,
                        width: blockWidth,
                        height: viewModel.blockHeight(for: block),
                        onTap: { onBlockTap(block) },
                        onToggleComplete: { viewModel.toggleBlockCompletion(block) }
                    )
                    .offset(
                        x: TimelineConstants.timeColumnWidth + TimelineConstants.blockHorizontalPadding,
                        y: viewModel.yPosition(for: block.startTime)
                    )
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TimelineView()
        .modelContainer(for: [TimeBlock.self, Routine.self, RoutineBlock.self], inMemory: true)
}
