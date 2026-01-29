import SwiftUI

/// Progress and analytics view showing completion statistics
/// Provides visual feedback and motivation for ADHD users
struct AnalyticsView: View {
    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var analyticsViewModel: AnalyticsViewModel

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary cards
                    summarySection

                    // Streak section
                    streakSection

                    // Daily chart
                    dailyChartSection

                    // Weekly chart
                    weeklyChartSection

                    // Priority breakdown
                    priorityBreakdownSection

                    // Tag breakdown
                    if !analyticsViewModel.completionsByTag.isEmpty {
                        tagBreakdownSection
                    }
                }
                .padding()
            }
            .background(AppColors.background(for: colorScheme))
            .navigationTitle("Progress")
            .refreshable {
                analyticsViewModel.refreshAnalytics()
            }
        }
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                SummaryCard(
                    title: "Today",
                    value: "\(analyticsViewModel.completedToday)",
                    icon: "checkmark.circle.fill",
                    color: AppColors.completed
                )

                SummaryCard(
                    title: "This Week",
                    value: "\(analyticsViewModel.completedThisWeek)",
                    icon: "calendar",
                    color: AppColors.softBlue
                )
            }

            HStack(spacing: 12) {
                SummaryCard(
                    title: "This Month",
                    value: "\(analyticsViewModel.completedThisMonth)",
                    icon: "calendar.badge.clock",
                    color: AppColors.sageGreen
                )

                SummaryCard(
                    title: "All Time",
                    value: "\(analyticsViewModel.totalCompleted)",
                    icon: "star.fill",
                    color: AppColors.primaryTeal
                )
            }
        }
    }

    // MARK: - Streak Section

    private var streakSection: some View {
        HStack(spacing: 20) {
            // Current streak
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(analyticsViewModel.currentStreak)")
                        .font(.title.weight(.bold))
                        .foregroundColor(AppColors.textPrimary(for: colorScheme))
                }

                Text("Current Streak")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary(for: colorScheme))
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 50)

            // Best streak
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                    Text("\(analyticsViewModel.longestStreak)")
                        .font(.title.weight(.bold))
                        .foregroundColor(AppColors.textPrimary(for: colorScheme))
                }

                Text("Best Streak")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary(for: colorScheme))
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 50)

            // Average per day
            VStack(spacing: 8) {
                Text(String(format: "%.1f", analyticsViewModel.averagePerDay))
                    .font(.title.weight(.bold))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))

                Text("Avg/Day")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary(for: colorScheme))
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(AppColors.cardBackground(for: colorScheme))
        .cornerRadius(Constants.cardCornerRadius)
    }

    // MARK: - Daily Chart Section

    private var dailyChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 7 Days")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary(for: colorScheme))

            BarChart(
                data: analyticsViewModel.dailyCompletions.map { ($0.dayLabel, $0.count) },
                barColor: AppColors.primaryTeal,
                height: 150
            )
        }
        .padding()
        .background(AppColors.cardBackground(for: colorScheme))
        .cornerRadius(Constants.cardCornerRadius)
    }

    // MARK: - Weekly Chart Section

    private var weeklyChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 4 Weeks")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary(for: colorScheme))

            BarChart(
                data: analyticsViewModel.weeklyCompletions.map { ($0.weekLabel, $0.count) },
                barColor: AppColors.softBlue,
                height: 150
            )
        }
        .padding()
        .background(AppColors.cardBackground(for: colorScheme))
        .cornerRadius(Constants.cardCornerRadius)
    }

    // MARK: - Priority Breakdown Section

    private var priorityBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completed by Priority")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary(for: colorScheme))

            HStack(spacing: 16) {
                ForEach(analyticsViewModel.completionsByPriority) { item in
                    VStack(spacing: 8) {
                        Circle()
                            .fill(item.priority.color)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text("\(item.count)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            )

                        Text(item.priority.label)
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary(for: colorScheme))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(AppColors.cardBackground(for: colorScheme))
        .cornerRadius(Constants.cardCornerRadius)
    }

    // MARK: - Tag Breakdown Section

    private var tagBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completed by Tag")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary(for: colorScheme))

            VStack(spacing: 8) {
                ForEach(analyticsViewModel.completionsByTag.prefix(5)) { item in
                    HStack {
                        Circle()
                            .fill(item.color)
                            .frame(width: 12, height: 12)

                        Text(item.tagName)
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))

                        Spacer()

                        Text("\(item.count)")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    }

                    // Progress bar
                    let maxCount = analyticsViewModel.completionsByTag.first?.count ?? 1
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(item.color.opacity(0.2))
                            .overlay(
                                HStack {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(item.color)
                                        .frame(width: geometry.size.width * CGFloat(item.count) / CGFloat(maxCount))
                                    Spacer()
                                }
                            )
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding()
        .background(AppColors.cardBackground(for: colorScheme))
        .cornerRadius(Constants.cardCornerRadius)
    }
}

// MARK: - Summary Card

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Spacer()
            }

            Text(value)
                .font(.title.weight(.bold))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))

            Text(title)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.cardBackground(for: colorScheme))
        .cornerRadius(Constants.cardCornerRadius)
    }
}

// MARK: - Bar Chart

struct BarChart: View {
    let data: [(label: String, value: Int)]
    let barColor: Color
    let height: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                VStack(spacing: 4) {
                    // Value label
                    Text("\(item.value)")
                        .font(.caption2)
                        .foregroundColor(AppColors.textSecondary(for: colorScheme))

                    // Bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(height: barHeight(for: item.value))

                    // Day label
                    Text(item.label)
                        .font(.caption2)
                        .foregroundColor(AppColors.textSecondary(for: colorScheme))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: height)
    }

    private var maxValue: Int {
        max(data.map(\.value).max() ?? 1, 1)
    }

    private func barHeight(for value: Int) -> CGFloat {
        let minHeight: CGFloat = 8
        let maxHeight: CGFloat = height - 40 // Leave room for labels
        let ratio = CGFloat(value) / CGFloat(maxValue)
        return max(minHeight, maxHeight * ratio)
    }
}

// MARK: - Preview

#Preview {
    AnalyticsView()
        .environmentObject(AnalyticsViewModel(context: PersistenceController.preview.container.viewContext))
}
