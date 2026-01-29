import SwiftUI

/// Settings view for app configuration
struct SettingsView: View {
    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var notificationManager: NotificationManager
    @EnvironmentObject private var tagViewModel: TagViewModel

    // MARK: - State

    @State private var showingTagManagement = false
    @State private var showingAbout = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // Notifications section
                notificationsSection

                // Tags section
                tagsSection

                // App section
                appSection

                // About section
                aboutSection
            }
            .navigationTitle("Settings")
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        Section {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(AppColors.primaryTeal)
                    .frame(width: 24)

                VStack(alignment: .leading) {
                    Text("Notifications")
                        .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    Text(notificationStatusText)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary(for: colorScheme))
                }

                Spacer()

                if !notificationManager.isAuthorized {
                    Button("Enable") {
                        Task {
                            let granted = await notificationManager.requestAuthorization()
                            if !granted {
                                notificationManager.openSettings()
                            }
                        }
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(AppColors.primaryTeal)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.completed)
                }
            }

            if notificationManager.isAuthorized {
                Button(action: {
                    notificationManager.openSettings()
                }) {
                    HStack {
                        Text("Notification Settings")
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(AppColors.textSecondary(for: colorScheme))
                    }
                }
            }
        } header: {
            Text("Notifications")
        }
    }

    private var notificationStatusText: String {
        switch notificationManager.authorizationStatus {
        case .authorized: return "Enabled"
        case .denied: return "Disabled in Settings"
        case .notDetermined: return "Not configured"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        Section {
            Button(action: { showingTagManagement = true }) {
                HStack {
                    Image(systemName: "tag.fill")
                        .foregroundColor(AppColors.sageGreen)
                        .frame(width: 24)

                    Text("Manage Tags")
                        .foregroundColor(AppColors.textPrimary(for: colorScheme))

                    Spacer()

                    Text("\(tagViewModel.tags.count)")
                        .foregroundColor(AppColors.textSecondary(for: colorScheme))

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary(for: colorScheme))
                }
            }
        } header: {
            Text("Organization")
        }
        .sheet(isPresented: $showingTagManagement) {
            TagManagementView()
        }
    }

    // MARK: - App Section

    private var appSection: some View {
        Section {
            // App version
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(AppColors.softBlue)
                    .frame(width: 24)

                Text("Version")
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))

                Spacer()

                Text(Constants.appVersion)
                    .foregroundColor(AppColors.textSecondary(for: colorScheme))
            }

            // iOS version
            HStack {
                Image(systemName: "iphone")
                    .foregroundColor(AppColors.softBlue)
                    .frame(width: 24)

                Text("iOS Version")
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))

                Spacer()

                Text(UIDevice.current.systemVersion)
                    .foregroundColor(AppColors.textSecondary(for: colorScheme))
            }
        } header: {
            Text("App Info")
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            Button(action: { showingAbout = true }) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(AppColors.priorityHigh)
                        .frame(width: 24)

                    Text("About ADHD Task Tracker")
                        .foregroundColor(AppColors.textPrimary(for: colorScheme))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary(for: colorScheme))
                }
            }
        } header: {
            Text("About")
        } footer: {
            Text("Designed with love for people with ADHD.")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary(for: colorScheme))
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // App icon placeholder
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(AppColors.primaryTeal)
                        .padding(.top, 20)

                    // App name
                    Text("ADHD Task Tracker")
                        .font(.title.weight(.bold))
                        .foregroundColor(AppColors.textPrimary(for: colorScheme))

                    // Version
                    Text("Version \(Constants.appVersion)")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary(for: colorScheme))

                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About This App")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))

                        Text("""
                        ADHD Task Tracker is designed specifically for people with ADHD who struggle with traditional task management apps.

                        We understand that ADHD brains work differently, so we've created an app that:
                        """)
                        .foregroundColor(AppColors.textSecondary(for: colorScheme))

                        VStack(alignment: .leading, spacing: 12) {
                            FeatureRow(icon: "eye.slash", text: "Minimizes visual clutter and distractions")
                            FeatureRow(icon: "hand.tap", text: "Makes task completion satisfying with animations")
                            FeatureRow(icon: "clock", text: "Provides flexible reminders that work for you")
                            FeatureRow(icon: "paintpalette", text: "Uses calming colors that don't overwhelm")
                            FeatureRow(icon: "chart.bar", text: "Celebrates your progress, not your failures")
                        }
                    }
                    .padding()
                    .background(AppColors.cardBackground(for: colorScheme))
                    .cornerRadius(Constants.cardCornerRadius)

                    // Tips section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tips for Success")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))

                        TipRow(number: 1, text: "Start with just 2-3 tasks per day to avoid overwhelm")
                        TipRow(number: 2, text: "Use the recurring tasks feature for daily habits")
                        TipRow(number: 3, text: "Celebrate completing tasks - every checkmark matters!")
                        TipRow(number: 4, text: "Don't be hard on yourself for overdue tasks")
                    }
                    .padding()
                    .background(AppColors.cardBackground(for: colorScheme))
                    .cornerRadius(Constants.cardCornerRadius)

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(AppColors.background(for: colorScheme))
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let text: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppColors.primaryTeal)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
        }
    }
}

// MARK: - Tip Row

struct TipRow: View {
    let number: Int
    let text: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(AppColors.primaryTeal)
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary(for: colorScheme))
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(NotificationManager.shared)
        .environmentObject(TagViewModel(context: PersistenceController.preview.container.viewContext))
}
