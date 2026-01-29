//
//  DailyRoutineBlocks_Complete.swift
//  Daily Routine Blocks - A Visual Time-Blocking App
//
//  SETUP INSTRUCTIONS:
//  1. Create new Xcode project: iOS → App, SwiftUI, SwiftData
//  2. Replace DailyRoutineBlocksApp.swift with the @main App section below
//  3. Replace ContentView.swift with everything else, OR split into separate files
//

import SwiftUI
import SwiftData
import Combine
import UserNotifications

// ============================================================================
// MARK: - APP ENTRY POINT
// ============================================================================

@main
struct DailyRoutineBlocksApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([TimeBlock.self, Routine.self, RoutineBlock.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(modelContainer)
    }
}

// ============================================================================
// MARK: - MODELS
// ============================================================================

// MARK: TimeBlock Model

@Model
final class TimeBlock {
    var id: UUID
    var title: String
    var startTime: Date
    var endTime: Date
    var colorHex: String
    var icon: String?
    var notes: String?
    var isCompleted: Bool
    var notificationEnabled: Bool
    var reminderMinutesBefore: Int?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        startTime: Date,
        endTime: Date,
        colorHex: String = BlockColor.blue.hex,
        icon: String? = nil,
        notes: String? = nil,
        isCompleted: Bool = false,
        notificationEnabled: Bool = false,
        reminderMinutesBefore: Int? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.colorHex = colorHex
        self.icon = icon
        self.notes = notes
        self.isCompleted = isCompleted
        self.notificationEnabled = notificationEnabled
        self.reminderMinutesBefore = reminderMinutesBefore
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var color: Color {
        Color(hex: colorHex) ?? .blue
    }

    var durationMinutes: Int {
        Calendar.current.dateComponents([.minute], from: startTime, to: endTime).minute ?? 0
    }

    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }

    var formattedDuration: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    static func sample(
        title: String = "Sample Block",
        startTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!,
        endTime: Date = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date())!,
        colorHex: String = BlockColor.blue.hex
    ) -> TimeBlock {
        TimeBlock(title: title, startTime: startTime, endTime: endTime, colorHex: colorHex)
    }
}

// MARK: Routine Model

@Model
final class Routine {
    var id: UUID
    var name: String
    @Relationship(deleteRule: .cascade) var blocks: [RoutineBlock]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        blocks: [RoutineBlock] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.blocks = blocks
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var sortedBlocks: [RoutineBlock] {
        blocks.sorted { $0.startMinutesFromMidnight < $1.startMinutesFromMidnight }
    }

    var totalDuration: Int {
        blocks.reduce(0) { $0 + $1.durationMinutes }
    }

    var formattedTotalDuration: String {
        let hours = totalDuration / 60
        let minutes = totalDuration % 60
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    func applyToDate(_ date: Date) -> [TimeBlock] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        return blocks.map { routineBlock in
            let startTime = calendar.date(byAdding: .minute, value: routineBlock.startMinutesFromMidnight, to: startOfDay)!
            let endTime = calendar.date(byAdding: .minute, value: routineBlock.durationMinutes, to: startTime)!

            return TimeBlock(
                title: routineBlock.title,
                startTime: startTime,
                endTime: endTime,
                colorHex: routineBlock.colorHex,
                icon: routineBlock.icon,
                notes: routineBlock.notes
            )
        }
    }
}

// MARK: RoutineBlock Model

@Model
final class RoutineBlock {
    var id: UUID
    var title: String
    var startMinutesFromMidnight: Int
    var durationMinutes: Int
    var colorHex: String
    var icon: String?
    var notes: String?

    @Relationship(inverse: \Routine.blocks) var routine: Routine?

    init(
        id: UUID = UUID(),
        title: String,
        startMinutesFromMidnight: Int,
        durationMinutes: Int,
        colorHex: String = BlockColor.blue.hex,
        icon: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.title = title
        self.startMinutesFromMidnight = startMinutesFromMidnight
        self.durationMinutes = durationMinutes
        self.colorHex = colorHex
        self.icon = icon
        self.notes = notes
    }

    var color: Color {
        Color(hex: colorHex) ?? .blue
    }

    var endMinutesFromMidnight: Int {
        startMinutesFromMidnight + durationMinutes
    }

    var formattedStartTime: String {
        let hours = startMinutesFromMidnight / 60
        let minutes = startMinutesFromMidnight % 60
        let period = hours < 12 ? "AM" : "PM"
        let displayHour = hours == 0 ? 12 : (hours > 12 ? hours - 12 : hours)
        return String(format: "%d:%02d %@", displayHour, minutes, period)
    }

    var formattedEndTime: String {
        let totalMinutes = endMinutesFromMidnight
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        let period = hours < 12 ? "AM" : "PM"
        let displayHour = hours == 0 ? 12 : (hours > 12 ? hours - 12 : hours)
        return String(format: "%d:%02d %@", displayHour, minutes, period)
    }

    var formattedTimeRange: String {
        "\(formattedStartTime) - \(formattedEndTime)"
    }

    var formattedDuration: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}

// ============================================================================
// MARK: - CONSTANTS
// ============================================================================

enum BlockColor: String, CaseIterable, Identifiable {
    case red, orange, yellow, green, teal, blue, indigo, purple, pink, gray, brown, mint

    var id: String { rawValue }

    var hex: String {
        switch self {
        case .red: return "#FF6B6B"
        case .orange: return "#FFA94D"
        case .yellow: return "#FFD43B"
        case .green: return "#69DB7C"
        case .teal: return "#38D9A9"
        case .blue: return "#4DABF7"
        case .indigo: return "#748FFC"
        case .purple: return "#B197FC"
        case .pink: return "#F783AC"
        case .gray: return "#868E96"
        case .brown: return "#A67C52"
        case .mint: return "#63E6BE"
        }
    }

    var color: Color { Color(hex: hex) ?? .blue }
    var name: String { rawValue.capitalized }
}

enum TimelineConstants {
    static let defaultStartHour: Int = 6
    static let defaultEndHour: Int = 23
    static let hourHeight: CGFloat = 60
    static let timeColumnWidth: CGFloat = 50
    static let blockHorizontalPadding: CGFloat = 8
    static let blockCornerRadius: CGFloat = 12
    static let minimumBlockDuration: Int = 15
    static let defaultBlockDuration: Int = 60
}

enum AppConstants {
    static let appName = "Daily Routine Blocks"
    static let defaultReminderMinutes: Int = 15
}

enum BlockIcon: String, CaseIterable, Identifiable {
    case run = "figure.run"
    case walk = "figure.walk"
    case yoga = "figure.yoga"
    case cooldown = "figure.cooldown"
    case strengthTraining = "figure.strengthtraining.traditional"
    case cycling = "figure.outdoor.cycle"
    case swimming = "figure.pool.swim"
    case laptop = "laptopcomputer"
    case desktopComputer = "desktopcomputer"
    case document = "doc.text"
    case folder = "folder"
    case calendar = "calendar"
    case videoCall = "video"
    case phone = "phone"
    case mail = "envelope"
    case chart = "chart.bar"
    case pencil = "pencil"
    case forkKnife = "fork.knife"
    case cup = "cup.and.saucer"
    case takeoutBag = "takeoutbag.and.cup.and.straw"
    case bed = "bed.double"
    case moon = "moon.stars"
    case alarm = "alarm"
    case heart = "heart"
    case brain = "brain.head.profile"
    case sparkles = "sparkles"
    case leaf = "leaf"
    case drop = "drop"
    case person = "person"
    case personTwo = "person.2"
    case personThree = "person.3"
    case bubble = "bubble.left"
    case house = "house"
    case car = "car"
    case bus = "bus"
    case train = "tram"
    case airplane = "airplane"
    case book = "book"
    case music = "music.note"
    case tv = "tv"
    case gamecontroller = "gamecontroller"
    case photo = "photo"
    case cart = "cart"
    case bag = "bag"
    case creditcard = "creditcard"
    case gift = "gift"
    case star = "star"
    case flag = "flag"
    case bolt = "bolt"
    case lightbulb = "lightbulb"

    var id: String { rawValue }
    var symbolName: String { rawValue }

    static var categorized: [(category: String, icons: [BlockIcon])] {
        [
            ("Fitness", [.run, .walk, .yoga, .cooldown, .strengthTraining, .cycling, .swimming]),
            ("Work", [.laptop, .desktopComputer, .document, .folder, .calendar, .videoCall, .phone, .mail, .chart, .pencil]),
            ("Food", [.forkKnife, .cup, .takeoutBag]),
            ("Sleep", [.bed, .moon, .alarm]),
            ("Self-care", [.heart, .brain, .sparkles, .leaf, .drop]),
            ("Social", [.person, .personTwo, .personThree, .bubble, .house]),
            ("Transport", [.car, .bus, .train, .airplane]),
            ("Entertainment", [.book, .music, .tv, .gamecontroller, .photo]),
            ("Other", [.cart, .bag, .creditcard, .gift, .star, .flag, .bolt, .lightbulb])
        ]
    }
}

enum UserDefaultsKeys {
    static let use24HourFormat = "use24HourFormat"
    static let defaultReminderEnabled = "defaultReminderEnabled"
    static let defaultReminderMinutes = "defaultReminderMinutes"
    static let timelineStartHour = "timelineStartHour"
    static let timelineEndHour = "timelineEndHour"
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
}

// ============================================================================
// MARK: - EXTENSIONS
// ============================================================================

// MARK: Color Extensions

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let length = hexSanitized.count
        switch length {
        case 6:
            self.init(
                red: Double((rgb & 0xFF0000) >> 16) / 255.0,
                green: Double((rgb & 0x00FF00) >> 8) / 255.0,
                blue: Double(rgb & 0x0000FF) / 255.0
            )
        case 8:
            self.init(
                red: Double((rgb & 0xFF000000) >> 24) / 255.0,
                green: Double((rgb & 0x00FF0000) >> 16) / 255.0,
                blue: Double((rgb & 0x0000FF00) >> 8) / 255.0,
                opacity: Double(rgb & 0x000000FF) / 255.0
            )
        default:
            return nil
        }
    }

    var isLight: Bool {
        guard let components = UIColor(self).cgColor.components else { return false }
        let r = components[0]
        let g = components.count > 1 ? components[1] : r
        let b = components.count > 2 ? components[2] : r
        let brightness = (r * 299 + g * 587 + b * 114) / 1000
        return brightness > 0.5
    }

    var contrastingTextColor: Color {
        isLight ? .black : .white
    }

    static let timelineBackground = Color(.systemBackground)
    static let gridLine = Color(.separator).opacity(0.3)
    static let currentTimeIndicator = Color.red
    static let blockShadow = Color.black.opacity(0.1)
}

// MARK: Date Extensions

extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
    var endOfDay: Date { Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-1) }
    var isToday: Bool { Calendar.current.isDateInToday(self) }
    var isYesterday: Bool { Calendar.current.isDateInYesterday(self) }
    var isTomorrow: Bool { Calendar.current.isDateInTomorrow(self) }
    var hour: Int { Calendar.current.component(.hour, from: self) }
    var minute: Int { Calendar.current.component(.minute, from: self) }

    var minutesFromMidnight: Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: self)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    func adding(minutes: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: minutes, to: self) ?? self
    }

    func adding(hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self) ?? self
    }

    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    func setting(hour: Int, minute: Int = 0) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: self) ?? self
    }

    func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: date)
    }

    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }

    var shortDayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }

    var dayNumber: Int { Calendar.current.component(.day, from: self) }

    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: self)
    }

    var shortMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: self)
    }

    var year: Int { Calendar.current.component(.year, from: self) }

    var formattedDate: String {
        if isToday { return "Today" }
        else if isYesterday { return "Yesterday" }
        else if isTomorrow { return "Tomorrow" }
        else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: self)
        }
    }

    var fullFormattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: self)
    }

    func formattedTime(use24Hour: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = use24Hour ? "HH:mm" : "h:mm a"
        return formatter.string(from: self)
    }

    func startOfWeek(using calendar: Calendar = .current) -> Date {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }

    func datesOfWeek() -> [Date] {
        let startOfWeek = self.startOfWeek()
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
}

// ============================================================================
// MARK: - VIEW MODELS
// ============================================================================

// MARK: TimelineViewModel

@MainActor
class TimelineViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var selectedBlock: TimeBlock?
    @Published var isShowingBlockCreation: Bool = false
    @Published var isShowingBlockDetail: Bool = false
    @Published var newBlockStartTime: Date = Date()
    @Published var currentTime: Date = Date()

    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()

    @AppStorage(UserDefaultsKeys.use24HourFormat) var use24HourFormat: Bool = false
    @AppStorage(UserDefaultsKeys.timelineStartHour) var startHour: Int = TimelineConstants.defaultStartHour
    @AppStorage(UserDefaultsKeys.timelineEndHour) var endHour: Int = TimelineConstants.defaultEndHour

    init() {
        setupCurrentTimeUpdates()
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func goToToday() { selectedDate = Date() }
    func goToPreviousDay() { selectedDate = selectedDate.adding(days: -1) }
    func goToNextDay() { selectedDate = selectedDate.adding(days: 1) }

    func toggleBlockCompletion(_ block: TimeBlock) {
        block.isCompleted.toggle()
        block.updatedAt = Date()
        try? modelContext?.save()
    }

    func showBlockCreation(at time: Date? = nil) {
        if let time = time {
            newBlockStartTime = time
        } else {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day, .hour], from: selectedDate)
            components.hour = (components.hour ?? 0) + 1
            newBlockStartTime = calendar.date(from: components) ?? selectedDate
        }
        isShowingBlockCreation = true
    }

    func showBlockDetail(for block: TimeBlock) {
        selectedBlock = block
        isShowingBlockDetail = true
    }

    func yPosition(for date: Date, hourHeight: CGFloat = TimelineConstants.hourHeight) -> CGFloat {
        let minutesFromStart = date.minutesFromMidnight - (startHour * 60)
        return CGFloat(minutesFromStart) * (hourHeight / 60)
    }

    func timeFromYPosition(_ y: CGFloat, hourHeight: CGFloat = TimelineConstants.hourHeight) -> Date {
        let minutesFromStart = Int(y / (hourHeight / 60))
        let totalMinutes = (startHour * 60) + minutesFromStart
        return selectedDate.startOfDay.adding(minutes: totalMinutes)
    }

    func blockHeight(for block: TimeBlock, hourHeight: CGFloat = TimelineConstants.hourHeight) -> CGFloat {
        let duration = CGFloat(block.durationMinutes)
        return duration * (hourHeight / 60)
    }

    func snapToNearestInterval(_ date: Date, interval: Int = 15) -> Date {
        let calendar = Calendar.current
        let minutes = calendar.component(.minute, from: date)
        let snappedMinutes = (minutes / interval) * interval
        return calendar.date(bySetting: .minute, value: snappedMinutes, of: date) ?? date
    }

    private func setupCurrentTimeUpdates() {
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.currentTime = Date() }
            .store(in: &cancellables)
    }

    var isCurrentDaySelected: Bool { selectedDate.isToday }
    var currentTimeYPosition: CGFloat { yPosition(for: currentTime) }
}

// MARK: SettingsViewModel

@MainActor
class SettingsViewModel: ObservableObject {
    @AppStorage(UserDefaultsKeys.use24HourFormat) var use24HourFormat: Bool = false
    @AppStorage(UserDefaultsKeys.defaultReminderEnabled) var defaultReminderEnabled: Bool = false
    @AppStorage(UserDefaultsKeys.defaultReminderMinutes) var defaultReminderMinutes: Int = AppConstants.defaultReminderMinutes
    @AppStorage(UserDefaultsKeys.timelineStartHour) var timelineStartHour: Int = TimelineConstants.defaultStartHour
    @AppStorage(UserDefaultsKeys.timelineEndHour) var timelineEndHour: Int = TimelineConstants.defaultEndHour

    @Published var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined

    init() {
        Task { await checkNotificationPermissions() }
    }

    func checkNotificationPermissions() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run { notificationPermissionStatus = settings.authorizationStatus }
    }

    func requestNotificationPermissions() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            await checkNotificationPermissions()
            return granted
        } catch { return false }
    }

    var reminderMinutesOptions: [Int] { [5, 10, 15, 30, 45, 60] }

    func resetToDefaults() {
        use24HourFormat = false
        defaultReminderEnabled = false
        defaultReminderMinutes = AppConstants.defaultReminderMinutes
        timelineStartHour = TimelineConstants.defaultStartHour
        timelineEndHour = TimelineConstants.defaultEndHour
    }

    func formatHour(_ hour: Int) -> String {
        if use24HourFormat { return String(format: "%02d:00", hour) }
        else if hour == 0 { return "12 AM" }
        else if hour < 12 { return "\(hour) AM" }
        else if hour == 12 { return "12 PM" }
        else { return "\(hour - 12) PM" }
    }

    func formatReminderMinutes(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes) minutes before" }
        else { return "\(minutes / 60) hour\(minutes >= 120 ? "s" : "") before" }
    }
}

// ============================================================================
// MARK: - MAIN VIEWS
// ============================================================================

// MARK: MainTabView

struct MainTabView: View {
    @State private var selectedTab: Tab = .timeline

    enum Tab: String {
        case timeline, routines, settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TimelineView()
                .tabItem { Label("Timeline", systemImage: "calendar.day.timeline.left") }
                .tag(Tab.timeline)

            RoutineListView()
                .tabItem { Label("Routines", systemImage: "repeat") }
                .tag(Tab.routines)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(Tab.settings)
        }
    }
}

// MARK: TimelineView

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
                            TimelineGridView(
                                startHour: viewModel.startHour,
                                endHour: viewModel.endHour,
                                use24HourFormat: viewModel.use24HourFormat
                            )

                            TimeBlocksContainerView(
                                blocks: blocksForSelectedDate,
                                viewModel: viewModel,
                                onBlockTap: { block in viewModel.showBlockDetail(for: block) },
                                onTimeSlotTap: { time in viewModel.showBlockCreation(at: time) }
                            )

                            if viewModel.isCurrentDaySelected {
                                CurrentTimeIndicatorView(
                                    yPosition: viewModel.currentTimeYPosition,
                                    timeColumnWidth: TimelineConstants.timeColumnWidth
                                )
                            }
                        }
                        .frame(minHeight: CGFloat(viewModel.endHour - viewModel.startHour) * TimelineConstants.hourHeight)
                    }
                    .onAppear {
                        scrollProxy = proxy
                        viewModel.setModelContext(modelContext)
                        if !hasScrolledToCurrentTime && viewModel.isCurrentDaySelected {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                scrollToCurrentTime()
                                hasScrolledToCurrentTime = true
                            }
                        }
                    }
                    .onChange(of: viewModel.selectedDate) { _, newDate in
                        if newDate.isToday { scrollToCurrentTime() }
                    }
                }
            }
            .navigationTitle("Timeline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { viewModel.showBlockCreation() }) {
                        Image(systemName: "plus.circle.fill").font(.title2)
                    }
                }
            }
            .sheet(isPresented: $viewModel.isShowingBlockCreation) {
                BlockCreationSheet(initialStartTime: viewModel.newBlockStartTime, selectedDate: viewModel.selectedDate)
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
        withAnimation { proxy.scrollTo("hour-\(targetHour)", anchor: .top) }
    }
}

// MARK: TimelineGridView

struct TimelineGridView: View {
    let startHour: Int
    let endHour: Int
    let use24HourFormat: Bool

    var body: some View {
        VStack(spacing: 0) {
            ForEach(startHour..<endHour, id: \.self) { hour in
                HStack(alignment: .top, spacing: 0) {
                    Text(formatHour(hour))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: TimelineConstants.timeColumnWidth, alignment: .trailing)
                        .padding(.trailing, 8)
                        .offset(y: -8)

                    VStack(spacing: 0) {
                        Rectangle().fill(Color.gridLine).frame(height: 1)
                        Spacer()
                    }
                }
                .frame(height: TimelineConstants.hourHeight)
                .id("hour-\(hour)")
            }
        }
    }

    private func formatHour(_ hour: Int) -> String {
        if use24HourFormat { return String(format: "%02d:00", hour) }
        else if hour == 0 { return "12 AM" }
        else if hour < 12 { return "\(hour) AM" }
        else if hour == 12 { return "12 PM" }
        else { return "\(hour - 12) PM" }
    }
}

// MARK: TimeBlocksContainerView

struct TimeBlocksContainerView: View {
    let blocks: [TimeBlock]
    let viewModel: TimelineViewModel
    let onBlockTap: (TimeBlock) -> Void
    let onTimeSlotTap: (Date) -> Void

    var body: some View {
        GeometryReader { geometry in
            let blockWidth = geometry.size.width - TimelineConstants.timeColumnWidth - (TimelineConstants.blockHorizontalPadding * 2)

            ZStack(alignment: .topLeading) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        let time = viewModel.timeFromYPosition(location.y)
                        let snappedTime = viewModel.snapToNearestInterval(time)
                        onTimeSlotTap(snappedTime)
                    }
                    .padding(.leading, TimelineConstants.timeColumnWidth)

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

// MARK: TimeBlockView

struct TimeBlockView: View {
    let block: TimeBlock
    let width: CGFloat
    let height: CGFloat
    let onTap: () -> Void
    let onToggleComplete: () -> Void

    private var backgroundColor: Color {
        block.color.opacity(block.isCompleted ? 0.5 : 1.0)
    }

    private var textColor: Color {
        block.color.contrastingTextColor.opacity(block.isCompleted ? 0.7 : 1.0)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                if let iconName = block.icon {
                    Image(systemName: iconName)
                        .font(.system(size: min(height * 0.3, 20)))
                        .foregroundStyle(textColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(block.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(textColor)
                        .strikethrough(block.isCompleted)
                        .lineLimit(1)

                    if height > 50 {
                        Text(block.formattedTimeRange)
                            .font(.caption2)
                            .foregroundStyle(textColor.opacity(0.8))
                    }
                }

                Spacer()

                if block.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(textColor)
                        .font(.system(size: 16))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(width: width, height: height, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: TimelineConstants.blockCornerRadius)
                    .fill(backgroundColor)
                    .shadow(color: .blockShadow, radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(BlockButtonStyle())
        .contextMenu {
            Button(action: onToggleComplete) {
                Label(block.isCompleted ? "Mark Incomplete" : "Mark Complete",
                      systemImage: block.isCompleted ? "circle" : "checkmark.circle")
            }
            Button(action: onTap) { Label("Edit", systemImage: "pencil") }
        }
    }
}

struct BlockButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: CurrentTimeIndicatorView

struct CurrentTimeIndicatorView: View {
    let yPosition: CGFloat
    let timeColumnWidth: CGFloat
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 0) {
            Spacer().frame(width: timeColumnWidth - 8)
            Circle()
                .fill(Color.currentTimeIndicator)
                .frame(width: 10, height: 10)
                .shadow(color: Color.currentTimeIndicator.opacity(0.5), radius: 4)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
            Rectangle()
                .fill(Color.currentTimeIndicator)
                .frame(height: 2)
                .shadow(color: Color.currentTimeIndicator.opacity(0.3), radius: 2)
        }
        .offset(y: yPosition - 5)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: DayNavigationView

struct DayNavigationView: View {
    @Binding var selectedDate: Date
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onToday: () -> Void

    @State private var isShowingDatePicker = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onPrevious) {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                }

                Spacer()

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

                Button(action: onNext) {
                    Image(systemName: "chevron.right")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)

            if !selectedDate.isToday {
                Button(action: onToday) {
                    Text("Today")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.blue.opacity(0.1)))
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
                DatePicker("Select Date", selection: $tempDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                Spacer()
            }
            .navigationTitle("Choose Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
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

// ============================================================================
// MARK: - BLOCK SHEETS
// ============================================================================

// MARK: BlockCreationSheet

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
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && endTime > startTime
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Block title", text: $title)
                        .focused($isTitleFocused)
                        .font(.headline)
                }

                Section("Time") {
                    DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                        .onChange(of: startTime) { _, newValue in
                            if endTime <= newValue {
                                endTime = newValue.adding(minutes: TimelineConstants.minimumBlockDuration)
                            }
                        }

                    DatePicker("End", selection: $endTime,
                               in: startTime.adding(minutes: TimelineConstants.minimumBlockDuration)...,
                               displayedComponents: .hourAndMinute)

                    HStack {
                        Text("Duration")
                        Spacer()
                        Text(formattedDuration).foregroundStyle(.secondary)
                    }
                }

                Section("Appearance") {
                    Button(action: { isShowingColorPicker = true }) {
                        HStack {
                            Text("Color")
                            Spacer()
                            Circle().fill(selectedColor.color).frame(width: 24, height: 24)
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)

                    Button(action: { isShowingIconPicker = true }) {
                        HStack {
                            Text("Icon")
                            Spacer()
                            if let icon = selectedIcon {
                                Image(systemName: icon).foregroundStyle(selectedColor.color)
                            } else {
                                Text("None").foregroundStyle(.secondary)
                            }
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                }

                Section("Notes") {
                    TextField("Add notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Notifications") {
                    Toggle("Reminder", isOn: $notificationEnabled)
                    if notificationEnabled {
                        Picker("Remind me", selection: $reminderMinutes) {
                            ForEach([5, 10, 15, 30, 45, 60], id: \.self) { minutes in
                                Text(formatReminderTime(minutes)).tag(minutes)
                            }
                        }
                    }
                }

                Section("Preview") {
                    BlockPreviewView(
                        title: title.isEmpty ? "Block Title" : title,
                        color: selectedColor.color,
                        icon: selectedIcon,
                        startTime: startTime,
                        endTime: endTime
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("New Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveBlock() }
                        .disabled(!isValid)
                        .fontWeight(.semibold)
                }
            }
            .onAppear { isTitleFocused = true }
            .sheet(isPresented: $isShowingColorPicker) {
                ColorPickerView(selectedColor: $selectedColor).presentationDetents([.medium])
            }
            .sheet(isPresented: $isShowingIconPicker) {
                IconPickerView(selectedIcon: $selectedIcon).presentationDetents([.large])
            }
        }
    }

    private var formattedDuration: String {
        let minutes = Calendar.current.dateComponents([.minute], from: startTime, to: endTime).minute ?? 0
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if hours > 0 && remainingMinutes > 0 { return "\(hours)h \(remainingMinutes)m" }
        else if hours > 0 { return "\(hours)h" }
        else { return "\(remainingMinutes)m" }
    }

    private func formatReminderTime(_ minutes: Int) -> String {
        minutes < 60 ? "\(minutes) minutes before" : "1 hour before"
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
        try? modelContext.save()
        dismiss()
    }
}

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

// MARK: BlockDetailSheet

struct BlockDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var block: TimeBlock

    @State private var title: String
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var selectedColor: BlockColor
    @State private var selectedIcon: String?
    @State private var notes: String
    @State private var notificationEnabled: Bool
    @State private var reminderMinutes: Int
    @State private var isCompleted: Bool

    @State private var isShowingColorPicker = false
    @State private var isShowingIconPicker = false
    @State private var isShowingDeleteConfirmation = false
    @State private var isEditing = false

    init(block: TimeBlock) {
        self.block = block
        _title = State(initialValue: block.title)
        _startTime = State(initialValue: block.startTime)
        _endTime = State(initialValue: block.endTime)
        _selectedColor = State(initialValue: BlockColor.allCases.first { $0.hex == block.colorHex } ?? .blue)
        _selectedIcon = State(initialValue: block.icon)
        _notes = State(initialValue: block.notes ?? "")
        _notificationEnabled = State(initialValue: block.notificationEnabled)
        _reminderMinutes = State(initialValue: block.reminderMinutesBefore ?? AppConstants.defaultReminderMinutes)
        _isCompleted = State(initialValue: block.isCompleted)
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && endTime > startTime
    }

    var body: some View {
        NavigationStack {
            Form {
                Section { Toggle("Completed", isOn: $isCompleted) }

                Section("Title") {
                    if isEditing {
                        TextField("Block title", text: $title).font(.headline)
                    } else {
                        Text(title)
                            .font(.headline)
                            .strikethrough(isCompleted)
                            .foregroundStyle(isCompleted ? .secondary : .primary)
                    }
                }

                Section("Time") {
                    if isEditing {
                        DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                            .onChange(of: startTime) { _, newValue in
                                if endTime <= newValue {
                                    endTime = newValue.adding(minutes: TimelineConstants.minimumBlockDuration)
                                }
                            }
                        DatePicker("End", selection: $endTime,
                                   in: startTime.adding(minutes: TimelineConstants.minimumBlockDuration)...,
                                   displayedComponents: .hourAndMinute)
                    } else {
                        HStack {
                            Text("Time")
                            Spacer()
                            Text(block.formattedTimeRange).foregroundStyle(.secondary)
                        }
                    }

                    HStack {
                        Text("Duration")
                        Spacer()
                        Text(formattedDuration).foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Date")
                        Spacer()
                        Text(block.startTime.formattedDate).foregroundStyle(.secondary)
                    }
                }

                Section("Appearance") {
                    if isEditing {
                        Button(action: { isShowingColorPicker = true }) {
                            HStack {
                                Text("Color")
                                Spacer()
                                Circle().fill(selectedColor.color).frame(width: 24, height: 24)
                                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .foregroundStyle(.primary)

                        Button(action: { isShowingIconPicker = true }) {
                            HStack {
                                Text("Icon")
                                Spacer()
                                if let icon = selectedIcon {
                                    Image(systemName: icon).foregroundStyle(selectedColor.color)
                                } else {
                                    Text("None").foregroundStyle(.secondary)
                                }
                                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .foregroundStyle(.primary)
                    } else {
                        HStack {
                            Text("Color")
                            Spacer()
                            Circle().fill(selectedColor.color).frame(width: 24, height: 24)
                        }

                        HStack {
                            Text("Icon")
                            Spacer()
                            if let icon = selectedIcon {
                                Image(systemName: icon).foregroundStyle(selectedColor.color)
                            } else {
                                Text("None").foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if isEditing || !notes.isEmpty {
                    Section("Notes") {
                        if isEditing {
                            TextField("Add notes...", text: $notes, axis: .vertical).lineLimit(3...6)
                        } else {
                            Text(notes.isEmpty ? "No notes" : notes)
                                .foregroundStyle(notes.isEmpty ? .secondary : .primary)
                        }
                    }
                }

                Section {
                    Button(role: .destructive) { isShowingDeleteConfirmation = true } label: {
                        HStack {
                            Spacer()
                            Text("Delete Block")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Block" : "Block Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if isEditing {
                        Button("Cancel") {
                            resetChanges()
                            isEditing = false
                        }
                    } else {
                        Button("Done") {
                            saveChanges()
                            dismiss()
                        }
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    if isEditing {
                        Button("Save") {
                            saveChanges()
                            isEditing = false
                        }
                        .disabled(!isValid)
                        .fontWeight(.semibold)
                    } else {
                        Button("Edit") { isEditing = true }
                    }
                }
            }
            .sheet(isPresented: $isShowingColorPicker) {
                ColorPickerView(selectedColor: $selectedColor).presentationDetents([.medium])
            }
            .sheet(isPresented: $isShowingIconPicker) {
                IconPickerView(selectedIcon: $selectedIcon).presentationDetents([.large])
            }
            .confirmationDialog("Delete Block", isPresented: $isShowingDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) { deleteBlock() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete '\(block.title)'? This action cannot be undone.")
            }
        }
    }

    private var formattedDuration: String {
        let minutes = Calendar.current.dateComponents([.minute], from: startTime, to: endTime).minute ?? 0
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if hours > 0 && remainingMinutes > 0 { return "\(hours)h \(remainingMinutes)m" }
        else if hours > 0 { return "\(hours)h" }
        else { return "\(remainingMinutes)m" }
    }

    private func saveChanges() {
        block.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        block.startTime = startTime
        block.endTime = endTime
        block.colorHex = selectedColor.hex
        block.icon = selectedIcon
        block.notes = notes.isEmpty ? nil : notes
        block.notificationEnabled = notificationEnabled
        block.reminderMinutesBefore = notificationEnabled ? reminderMinutes : nil
        block.isCompleted = isCompleted
        block.updatedAt = Date()
        try? modelContext.save()
    }

    private func resetChanges() {
        title = block.title
        startTime = block.startTime
        endTime = block.endTime
        selectedColor = BlockColor.allCases.first { $0.hex == block.colorHex } ?? .blue
        selectedIcon = block.icon
        notes = block.notes ?? ""
        notificationEnabled = block.notificationEnabled
        reminderMinutes = block.reminderMinutesBefore ?? AppConstants.defaultReminderMinutes
        isCompleted = block.isCompleted
    }

    private func deleteBlock() {
        modelContext.delete(block)
        try? modelContext.save()
        dismiss()
    }
}

// ============================================================================
// MARK: - PICKER VIEWS
// ============================================================================

// MARK: ColorPickerView

struct ColorPickerView: View {
    @Binding var selectedColor: BlockColor
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 60, maximum: 80), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(BlockColor.allCases) { color in
                        ColorOptionView(color: color, isSelected: selectedColor == color)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedColor = color
                                }
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { dismiss() }
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }
}

struct ColorOptionView: View {
    let color: BlockColor
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.color)
                    .frame(width: 56, height: 56)
                    .shadow(color: color.color.opacity(0.4), radius: isSelected ? 8 : 4)

                if isSelected {
                    Circle()
                        .strokeBorder(.white, lineWidth: 3)
                        .frame(width: 56, height: 56)

                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(color.color.contrastingTextColor)
                }
            }
            .scaleEffect(isSelected ? 1.1 : 1.0)

            Text(color.name)
                .font(.caption)
                .foregroundStyle(isSelected ? .primary : .secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: IconPickerView

struct IconPickerView: View {
    @Binding var selectedIcon: String?
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredCategories: [(category: String, icons: [BlockIcon])] {
        if searchText.isEmpty { return BlockIcon.categorized }

        let lowercasedSearch = searchText.lowercased()
        return BlockIcon.categorized.compactMap { category, icons in
            let filteredIcons = icons.filter { icon in
                icon.rawValue.lowercased().contains(lowercasedSearch) ||
                category.lowercased().contains(lowercasedSearch)
            }
            return filteredIcons.isEmpty ? nil : (category, filteredIcons)
        }
    }

    private let columns = [GridItem(.adaptive(minimum: 50, maximum: 60), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if searchText.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Button {
                                selectedIcon = nil
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "circle.slash")
                                        .font(.title2)
                                        .foregroundStyle(.secondary)
                                    Text("No Icon").foregroundStyle(.primary)
                                    Spacer()
                                    if selectedIcon == nil {
                                        Image(systemName: "checkmark").foregroundStyle(.blue)
                                    }
                                }
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                            }
                        }
                        .padding(.horizontal)
                    }

                    ForEach(filteredCategories, id: \.category) { category, icons in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(category)
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)

                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(icons) { icon in
                                    IconOptionView(icon: icon, isSelected: selectedIcon == icon.symbolName)
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedIcon = icon.symbolName
                                            }
                                            let generator = UIImpactFeedbackGenerator(style: .light)
                                            generator.impactOccurred()
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { dismiss() }
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    if filteredCategories.isEmpty {
                        ContentUnavailableView("No Icons Found", systemImage: "magnifyingglass",
                                               description: Text("Try a different search term"))
                            .padding(.top, 40)
                    }
                }
                .padding(.vertical)
            }
            .searchable(text: $searchText, prompt: "Search icons")
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }
}

struct IconOptionView: View {
    let icon: BlockIcon
    let isSelected: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue : Color(.secondarySystemBackground))
                .frame(width: 50, height: 50)

            Image(systemName: icon.symbolName)
                .font(.system(size: 22))
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(isSelected ? Color.blue : Color.clear, lineWidth: 2))
        .scaleEffect(isSelected ? 1.05 : 1.0)
    }
}

// ============================================================================
// MARK: - ROUTINES
// ============================================================================

// MARK: RoutineListView

struct RoutineListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Routine.name) private var routines: [Routine]

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
                                Button(role: .destructive) { deleteRoutine(routine) } label: {
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
                                Button { duplicateRoutine(routine) } label: {
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
                        Image(systemName: "plus.circle.fill").font(.title2)
                    }
                }
            }
            .sheet(isPresented: $isShowingNewRoutine) { NewRoutineSheet() }
            .sheet(isPresented: $isShowingApplySheet) {
                if let routine = selectedRoutineForApply {
                    ApplyRoutineSheet(routine: routine, selectedDate: $applyToDate) {
                        applyRoutine(routine, toDate: applyToDate)
                    }
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
        let newRoutine = Routine(name: "\(routine.name) (Copy)", blocks: newBlocks)
        modelContext.insert(newRoutine)
        try? modelContext.save()
    }

    private func applyRoutine(_ routine: Routine, toDate date: Date) {
        let timeBlocks = routine.applyToDate(date)
        for block in timeBlocks { modelContext.insert(block) }
        try? modelContext.save()
    }
}

struct RoutineRowView: View {
    let routine: Routine

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(routine.name).font(.headline)

            HStack(spacing: 16) {
                Label("\(routine.blocks.count) blocks", systemImage: "square.stack")
                    .font(.caption).foregroundStyle(.secondary)
                Label(routine.formattedTotalDuration, systemImage: "clock")
                    .font(.caption).foregroundStyle(.secondary)
            }

            HStack(spacing: 4) {
                ForEach(routine.sortedBlocks.prefix(6)) { block in
                    Circle().fill(block.color).frame(width: 12, height: 12)
                }
                if routine.blocks.count > 6 {
                    Text("+\(routine.blocks.count - 6)")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct EmptyRoutinesView: View {
    let onCreateTapped: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No Routines", systemImage: "repeat")
        } description: {
            Text("Create routines to quickly fill your day with preset time blocks")
        } actions: {
            Button(action: onCreateTapped) { Text("Create Routine") }
                .buttonStyle(.borderedProminent)
        }
    }
}

struct ApplyRoutineSheet: View {
    let routine: Routine
    @Binding var selectedDate: Date
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text(routine.name).font(.title2.weight(.semibold))
                    Text("\(routine.blocks.count) blocks • \(routine.formattedTotalDuration)")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .padding(.top)

                DatePicker("Apply to", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding(.horizontal)

                Spacer()

                Button(action: { onApply(); dismiss() }) {
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
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }
}

struct NewRoutineSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @FocusState private var isNameFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Routine name", text: $name).focused($isNameFocused)
                } footer: {
                    Text("You can add blocks after creating the routine")
                }
            }
            .navigationTitle("New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { createRoutine() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .fontWeight(.semibold)
                }
            }
            .onAppear { isNameFocused = true }
        }
    }

    private func createRoutine() {
        let routine = Routine(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
        modelContext.insert(routine)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: RoutineDetailView

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
            Section {
                if isEditing {
                    TextField("Routine name", text: $editedName).font(.headline)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(routine.name).font(.title2.weight(.semibold))
                        HStack(spacing: 16) {
                            Label("\(routine.blocks.count) blocks", systemImage: "square.stack")
                            Label(routine.formattedTotalDuration, systemImage: "clock")
                        }
                        .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                if routine.blocks.isEmpty {
                    ContentUnavailableView {
                        Label("No Blocks", systemImage: "square.dashed")
                    } description: {
                        Text("Add blocks to build your routine")
                    } actions: {
                        Button("Add Block") { isShowingAddBlock = true }
                    }
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(routine.sortedBlocks) { block in
                        RoutineBlockRowView(block: block)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedBlock = block }
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

            Section {
                Button(role: .destructive) { isShowingDeleteConfirmation = true } label: {
                    HStack { Spacer(); Text("Delete Routine"); Spacer() }
                }
            }
        }
        .navigationTitle("Routine Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if isEditing {
                    Button("Done") { saveChanges(); isEditing = false }.fontWeight(.semibold)
                } else {
                    Button("Edit") { editedName = routine.name; isEditing = true }
                }
            }
        }
        .sheet(isPresented: $isShowingAddBlock) { AddRoutineBlockSheet(routine: routine) }
        .sheet(item: $selectedBlock) { block in EditRoutineBlockSheet(routine: routine, block: block) }
        .confirmationDialog("Delete Routine", isPresented: $isShowingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deleteRoutine() }
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

struct RoutineBlockRowView: View {
    let block: RoutineBlock

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(block.color)
                .frame(width: 4, height: 44)

            if let iconName = block.icon {
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundStyle(block.color)
                    .frame(width: 32)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(block.title).font(.headline)
                Text(block.formattedTimeRange).font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            Text(block.formattedDuration).font(.subheadline).foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

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

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Block title", text: $title).focused($isTitleFocused)
                }

                Section("Time") {
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
                }

                Section("Appearance") {
                    Button(action: { isShowingColorPicker = true }) {
                        HStack {
                            Text("Color")
                            Spacer()
                            Circle().fill(selectedColor.color).frame(width: 24, height: 24)
                        }
                    }
                    .foregroundStyle(.primary)

                    Button(action: { isShowingIconPicker = true }) {
                        HStack {
                            Text("Icon")
                            Spacer()
                            if let icon = selectedIcon {
                                Image(systemName: icon).foregroundStyle(selectedColor.color)
                            } else {
                                Text("None").foregroundStyle(.secondary)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
            .navigationTitle("Add Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addBlock() }
                        .disabled(!isValid).fontWeight(.semibold)
                }
            }
            .onAppear { isTitleFocused = true }
            .sheet(isPresented: $isShowingColorPicker) {
                ColorPickerView(selectedColor: $selectedColor).presentationDetents([.medium])
            }
            .sheet(isPresented: $isShowingIconPicker) {
                IconPickerView(selectedIcon: $selectedIcon).presentationDetents([.large])
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
        if hours > 0 && mins > 0 { return "\(hours)h \(mins)m" }
        else if hours > 0 { return "\(hours) hour\(hours > 1 ? "s" : "")" }
        else { return "\(mins) minutes" }
    }

    private func addBlock() {
        let block = RoutineBlock(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            startMinutesFromMidnight: startHour * 60 + startMinute,
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
                Section("Title") {
                    TextField("Block title", text: $title)
                }

                Section("Time") {
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
                }

                Section("Appearance") {
                    Button(action: { isShowingColorPicker = true }) {
                        HStack {
                            Text("Color")
                            Spacer()
                            Circle().fill(selectedColor.color).frame(width: 24, height: 24)
                        }
                    }
                    .foregroundStyle(.primary)

                    Button(action: { isShowingIconPicker = true }) {
                        HStack {
                            Text("Icon")
                            Spacer()
                            if let icon = selectedIcon {
                                Image(systemName: icon).foregroundStyle(selectedColor.color)
                            } else {
                                Text("None").foregroundStyle(.secondary)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }

                Section {
                    Button(role: .destructive) { isShowingDeleteConfirmation = true } label: {
                        HStack { Spacer(); Text("Delete Block"); Spacer() }
                    }
                }
            }
            .navigationTitle("Edit Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .disabled(!isValid).fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $isShowingColorPicker) {
                ColorPickerView(selectedColor: $selectedColor).presentationDetents([.medium])
            }
            .sheet(isPresented: $isShowingIconPicker) {
                IconPickerView(selectedIcon: $selectedIcon).presentationDetents([.large])
            }
            .confirmationDialog("Delete Block", isPresented: $isShowingDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) { deleteBlock() }
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
        if hours > 0 && mins > 0 { return "\(hours)h \(mins)m" }
        else if hours > 0 { return "\(hours) hour\(hours > 1 ? "s" : "")" }
        else { return "\(mins) minutes" }
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

// ============================================================================
// MARK: - SETTINGS VIEW
// ============================================================================

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var isShowingResetConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Time Format") {
                    Toggle("Use 24-Hour Time", isOn: $viewModel.use24HourFormat)
                } footer: {
                    Text("Changes how times are displayed throughout the app")
                }

                Section("Timeline") {
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
                } footer: {
                    Text("Set the visible hours in your daily timeline")
                }

                Section("Notifications") {
                    Toggle("Default Reminder", isOn: $viewModel.defaultReminderEnabled)

                    if viewModel.defaultReminderEnabled {
                        Picker("Remind Before", selection: $viewModel.defaultReminderMinutes) {
                            ForEach(viewModel.reminderMinutesOptions, id: \.self) { minutes in
                                Text(viewModel.formatReminderMinutes(minutes)).tag(minutes)
                            }
                        }
                    }

                    NotificationPermissionRow(viewModel: viewModel)
                } footer: {
                    Text("New blocks will have reminders enabled by default")
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0").foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button(role: .destructive) { isShowingResetConfirmation = true } label: {
                        HStack { Spacer(); Text("Reset to Defaults"); Spacer() }
                    }
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog("Reset Settings", isPresented: $isShowingResetConfirmation, titleVisibility: .visible) {
                Button("Reset", role: .destructive) { viewModel.resetToDefaults() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will reset all settings to their default values. Your blocks and routines will not be affected.")
            }
        }
    }
}

struct NotificationPermissionRow: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        HStack {
            Text("Notification Permission")
            Spacer()

            switch viewModel.notificationPermissionStatus {
            case .authorized:
                Label("Enabled", systemImage: "checkmark.circle.fill")
                    .font(.subheadline).foregroundStyle(.green)
            case .denied:
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.subheadline)
            case .notDetermined:
                Button("Enable") { Task { await viewModel.requestNotificationPermissions() } }
                    .font(.subheadline)
            default:
                Text("Unknown").font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}
