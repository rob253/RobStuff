//
//  SettingsView.swift
//  DailyRoutineBlocks
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var isShowingResetConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                // Time Format Section
                Section {
                    Toggle("Use 24-Hour Time", isOn: $viewModel.use24HourFormat)
                } header: {
                    Text("Time Format")
                } footer: {
                    Text("Changes how times are displayed throughout the app")
                }

                // Timeline Section
                Section {
                    Picker("Day Starts At", selection: $viewModel.timelineStartHour) {
                        ForEach(0..<viewModel.timelineEndHour, id: \.self) { hour in
                            Text(viewModel.formatHour(hour)).tag(hour)
                        }
                    }

                    Picker("Day Ends At", selection: $viewModel.timelineEndHour) {
                        ForEach((viewModel.timelineStartHour + 1)...24, id: \.self) { hour in
                            Text(viewModel.formatHour(hour)).tag(hour)
                        }
                    }
                } header: {
                    Text("Timeline")
                } footer: {
                    Text("Set the visible hours in your daily timeline")
                }

                // Notifications Section
                Section {
                    Toggle("Default Reminder", isOn: $viewModel.defaultReminderEnabled)

                    if viewModel.defaultReminderEnabled {
                        Picker("Remind Before", selection: $viewModel.defaultReminderMinutes) {
                            ForEach(viewModel.reminderMinutesOptions, id: \.self) { minutes in
                                Text(viewModel.formatReminderMinutes(minutes)).tag(minutes)
                            }
                        }
                    }

                    NotificationPermissionRow(viewModel: viewModel)
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("New blocks will have reminders enabled by default")
                }

                // About Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                }

                // Reset Section
                Section {
                    Button(role: .destructive) {
                        isShowingResetConfirmation = true
                    } label: {
                        HStack {
                            Text("Reset to Defaults")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Reset Settings",
                isPresented: $isShowingResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    viewModel.resetToDefaults()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will reset all settings to their default values. Your blocks and routines will not be affected.")
            }
        }
    }
}

// MARK: - Notification Permission Row

struct NotificationPermissionRow: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        HStack {
            Text("Notification Permission")

            Spacer()

            switch viewModel.notificationPermissionStatus {
            case .authorized:
                Label("Enabled", systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.green)

            case .denied:
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.subheadline)

            case .notDetermined:
                Button("Enable") {
                    Task {
                        await viewModel.requestNotificationPermissions()
                    }
                }
                .font(.subheadline)

            case .provisional, .ephemeral:
                Text("Limited")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

            @unknown default:
                Text("Unknown")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
