# ADHD Task Tracker

A task management iOS app designed specifically for people with ADHD. This app focuses on minimizing cognitive load, providing satisfying interactions, and using calming colors to create a stress-free task management experience.

## Features

### Core Features
- **Task Management**: Create, edit, and delete tasks with ease
- **Recurring Tasks**: Support for daily, weekly, bi-weekly, and monthly recurring tasks
- **Priority Levels**: High, Medium, and Low priorities with visual color indicators
- **Tagging System**: Create custom tags with customizable colors for organization
- **Quick Add**: Minimal-friction task creation with smart defaults

### Views & Organization
- **Today View**: Focus on what matters today with encouraging messaging
- **Task List**: Full list with filtering by priority, tags, and status
- **Calendar View**: Month and week views for planning ahead
- **Search**: Quickly find tasks by title or description

### Progress Tracking
- **Daily & Weekly Stats**: Track tasks completed over time
- **Streaks**: See your current and longest completion streaks
- **Priority Breakdown**: Visualize completions by priority level
- **Tag Analytics**: See which areas you're most productive in

### Notifications
- **Configurable Reminders**: At due time, 15/30/60 minutes before, and more
- **Per-Task Control**: Enable/disable notifications for individual tasks
- **Smart Actions**: Mark complete or snooze directly from notifications

## Design Philosophy

### ADHD-Friendly Features
- **Clean, Uncluttered Interface**: Plenty of white space and clear visual hierarchy
- **Calming Color Palette**: Soft blues and greens that don't overwhelm
- **Large Touch Targets**: Easy-to-tap buttons and controls
- **Satisfying Completion**: Animations and haptic feedback when completing tasks
- **Encouraging Empty States**: Friendly messages instead of blank screens
- **Minimal Steps**: Quick paths to add or complete tasks
- **Smart Defaults**: Reduces decision fatigue

### Color Palette
- **Primary Teal**: #5E9EA0
- **Soft Blue**: #6B9AC4
- **Sage Green**: #B2C9AB
- **Light Sea Green**: #7FB3A5

### Priority Colors
- **High**: Muted Coral (#E07A5F)
- **Medium**: Soft Amber (#E9C46A)
- **Low**: Gray Blue (#8FA9B8)

## Technical Requirements

- iOS 15.0+
- Swift 5.9+
- Xcode 15.0+

## Project Setup

### Creating the Xcode Project

1. Open Xcode and create a new project
2. Select "App" under iOS
3. Configure:
   - Product Name: `ADHDTaskTracker`
   - Team: Your development team
   - Organization Identifier: Your identifier
   - Interface: SwiftUI
   - Language: Swift
   - Storage: Core Data ✓
   - Include Tests: Optional

4. Delete the default files Xcode creates
5. Copy all files from `ADHDTaskTracker/` folder into your project

### File Structure

```
ADHDTaskTracker/
├── App/
│   ├── ADHDTaskTrackerApp.swift      # Main app entry point
│   └── ContentView.swift              # Tab-based main view
├── Models/
│   ├── ADHDTaskTracker.xcdatamodeld/  # Core Data model
│   ├── PersistenceController.swift    # Core Data stack
│   ├── TaskEntity+Extensions.swift    # Task model extensions
│   └── TagEntity+Extensions.swift     # Tag model extensions
├── ViewModels/
│   ├── TaskViewModel.swift            # Task operations
│   ├── TagViewModel.swift             # Tag operations
│   ├── AnalyticsViewModel.swift       # Progress tracking
│   └── NotificationManager.swift      # Push notifications
├── Views/
│   ├── Tasks/
│   │   ├── TaskListView.swift
│   │   ├── TaskRowView.swift
│   │   ├── AddTaskView.swift
│   │   └── EditTaskView.swift
│   ├── Calendar/
│   │   └── CalendarView.swift
│   ├── Tags/
│   │   └── TagManagementView.swift
│   ├── Analytics/
│   │   └── AnalyticsView.swift
│   ├── Settings/
│   │   └── SettingsView.swift
│   └── Components/
│       ├── PriorityBadge.swift
│       ├── TagBadge.swift
│       ├── EmptyStateView.swift
│       └── FlowLayout.swift
├── Utilities/
│   ├── AppColors.swift                # Color system
│   ├── Constants.swift                # App constants
│   └── DateExtensions.swift           # Date helpers
└── Resources/
    └── (Assets would go here)
```

### Build Settings

1. Set iOS Deployment Target to 15.0
2. Enable "Supports Dark Mode" in your app's Info.plist
3. Add the following keys to Info.plist for notifications:
   - `UIBackgroundModes` with `remote-notification`

### Core Data Setup

The Core Data model (`ADHDTaskTracker.xcdatamodeld`) includes:

**TaskEntity**
- id: UUID
- title: String
- taskDescription: String?
- dueDate: Date
- createdAt: Date
- completedAt: Date?
- isCompleted: Boolean
- priority: Int16 (0=Low, 1=Medium, 2=High)
- notificationEnabled: Boolean
- notificationMinutesBefore: Int32
- isRecurring: Boolean
- recurringPattern: String?
- recurringInterval: Int32
- recurringEndDate: Date?
- parentTaskId: UUID?
- tags: Relationship → TagEntity

**TagEntity**
- id: UUID
- name: String
- colorHex: String
- createdAt: Date
- tasks: Relationship → TaskEntity

**CompletionRecordEntity**
- id: UUID
- taskId: UUID
- completedAt: Date
- taskTitle: String
- taskPriority: Int16

## Usage

### Adding a Task
1. Tap the floating + button
2. Enter task title (required)
3. Select priority (default: Medium)
4. Choose due date (defaults: Today in 1 hour)
5. Select tags (optional)
6. Configure notifications (optional)
7. Tap "Add"

### Completing a Task
- Tap the circle checkbox on any task
- Swipe left to complete
- Tap the task for details, then "Mark Complete"

### Filtering Tasks
- Use the filter button in the task list
- Filter by status, priority, or tags
- Combine multiple filters

### Managing Tags
- Go to Settings → Manage Tags
- Create tags with custom colors
- Edit or delete existing tags

## Contributing

Feel free to submit issues and pull requests for improvements.

## License

MIT License

## Acknowledgments

Designed with understanding and empathy for people with ADHD. We believe everyone deserves tools that work with their brain, not against it.
