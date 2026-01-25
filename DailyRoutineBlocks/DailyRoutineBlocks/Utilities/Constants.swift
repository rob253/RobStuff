//
//  Constants.swift
//  DailyRoutineBlocks
//

import Foundation
import SwiftUI

// MARK: - Block Colors

enum BlockColor: String, CaseIterable, Identifiable {
    case red
    case orange
    case yellow
    case green
    case teal
    case blue
    case indigo
    case purple
    case pink
    case gray
    case brown
    case mint

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

    var color: Color {
        Color(hex: hex) ?? .blue
    }

    var name: String {
        rawValue.capitalized
    }
}

// MARK: - Timeline Constants

enum TimelineConstants {
    static let defaultStartHour: Int = 6
    static let defaultEndHour: Int = 23
    static let hourHeight: CGFloat = 60
    static let timeColumnWidth: CGFloat = 50
    static let blockHorizontalPadding: CGFloat = 8
    static let blockCornerRadius: CGFloat = 12
    static let minimumBlockDuration: Int = 15 // minutes
    static let defaultBlockDuration: Int = 60 // minutes
}

// MARK: - App Constants

enum AppConstants {
    static let appName = "Daily Routine Blocks"
    static let defaultReminderMinutes: Int = 15
}

// MARK: - SF Symbols for Icons

enum BlockIcon: String, CaseIterable, Identifiable {
    // Fitness
    case run = "figure.run"
    case walk = "figure.walk"
    case yoga = "figure.yoga"
    case cooldown = "figure.cooldown"
    case strengthTraining = "figure.strengthtraining.traditional"
    case cycling = "figure.outdoor.cycle"
    case swimming = "figure.pool.swim"

    // Work
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

    // Food
    case forkKnife = "fork.knife"
    case cup = "cup.and.saucer"
    case takeoutBag = "takeoutbag.and.cup.and.straw"

    // Sleep
    case bed = "bed.double"
    case moon = "moon.stars"
    case alarm = "alarm"

    // Self-care
    case heart = "heart"
    case brain = "brain.head.profile"
    case sparkles = "sparkles"
    case leaf = "leaf"
    case drop = "drop"

    // Social
    case person = "person"
    case personTwo = "person.2"
    case personThree = "person.3"
    case bubble = "bubble.left"
    case house = "house"

    // Transport
    case car = "car"
    case bus = "bus"
    case train = "tram"
    case airplane = "airplane"

    // Entertainment
    case book = "book"
    case music = "music.note"
    case tv = "tv"
    case gamecontroller = "gamecontroller"
    case photo = "photo"

    // Other
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

// MARK: - User Defaults Keys

enum UserDefaultsKeys {
    static let use24HourFormat = "use24HourFormat"
    static let defaultReminderEnabled = "defaultReminderEnabled"
    static let defaultReminderMinutes = "defaultReminderMinutes"
    static let timelineStartHour = "timelineStartHour"
    static let timelineEndHour = "timelineEndHour"
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
}
