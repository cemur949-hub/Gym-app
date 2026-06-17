import Foundation
import SwiftUI

// MARK: - Color Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    static let appBackground  = Color(hex: "0A0A0A")
    static let cardBackground = Color(hex: "171717")
    static let cardSurface    = Color(hex: "222222")
    static let textSecondary  = Color(hex: "8E8E93")
    static let divider        = Color(hex: "2C2C2E")
}

// MARK: - SplitType
enum SplitType: String, CaseIterable, Codable, Identifiable {
    case push      = "Push"
    case pull      = "Pull"
    case legs      = "Legs"
    case upper     = "Upper"
    case lower     = "Lower"
    case fullBody  = "Full Body"
    case cardio    = "Cardio"
    case core      = "Core"
    case arms      = "Arms"
    case chest     = "Chest"
    case back      = "Back"
    case shoulders = "Shoulders"
    case custom    = "Custom"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .push:      return "arrow.up.circle.fill"
        case .pull:      return "arrow.down.circle.fill"
        case .legs:      return "figure.walk"
        case .upper:     return "figure.arms.open"
        case .lower:     return "figure.run"
        case .fullBody:  return "figure.strengthtraining.traditional"
        case .cardio:    return "heart.circle.fill"
        case .core:      return "scope"
        case .arms:      return "dumbbell.fill"
        case .chest:     return "lungs.fill"
        case .back:      return "arrow.triangle.2.circlepath"
        case .shoulders: return "person.bust"
        case .custom:    return "star.fill"
        }
    }

    var colorHex: String {
        switch self {
        case .push:      return "FF6B35"
        case .pull:      return "4ECDC4"
        case .legs:      return "45B7D1"
        case .upper:     return "96CEB4"
        case .lower:     return "FFEAA7"
        case .fullBody:  return "DDA0DD"
        case .cardio:    return "FF6B6B"
        case .core:      return "98D8C8"
        case .arms:      return "F7DC6F"
        case .chest:     return "E8A0BF"
        case .back:      return "A8E6CF"
        case .shoulders: return "FFD93D"
        case .custom:    return "C3B1E1"
        }
    }

    var color: Color { Color(hex: colorHex) }
}

// MARK: - Exercise
struct Exercise: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var sets: Int
    var reps: String
    var weight: String
    var restSeconds: Int
    var notes: String

    init(
        id: UUID = UUID(),
        name: String = "",
        sets: Int = 3,
        reps: String = "10",
        weight: String = "",
        restSeconds: Int = 60,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.sets = sets
        self.reps = reps
        self.weight = weight
        self.restSeconds = restSeconds
        self.notes = notes
    }

    var displayString: String {
        var parts = ["\(sets) × \(reps)"]
        if !weight.isEmpty { parts.append("@ \(weight)") }
        return parts.joined(separator: " ")
    }

    var restDisplay: String {
        if restSeconds == 0 { return "No rest" }
        if restSeconds < 60 { return "\(restSeconds)s" }
        let m = restSeconds / 60
        let s = restSeconds % 60
        return s == 0 ? "\(m)m" : "\(m)m \(s)s"
    }
}

// MARK: - Workout
struct Workout: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var split: SplitType
    var exercises: [Exercise]
    var notes: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String = "",
        split: SplitType = .custom,
        exercises: [Exercise] = [],
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.split = split
        self.exercises = exercises
        self.notes = notes
        self.createdAt = createdAt
    }
}

// MARK: - WorkoutProgram
struct WorkoutProgram: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var description: String
    var emoji: String
    var workouts: [Workout]
    var createdAt: Date
    var colorHex: String

    init(
        id: UUID = UUID(),
        name: String = "",
        description: String = "",
        emoji: String = "💪",
        workouts: [Workout] = [],
        createdAt: Date = Date(),
        colorHex: String = "FF6B35"
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.emoji = emoji
        self.workouts = workouts
        self.createdAt = createdAt
        self.colorHex = colorHex
    }

    var color: Color { Color(hex: colorHex) }

    var totalExercises: Int { workouts.reduce(0) { $0 + $1.exercises.count } }

    var availableSplits: [SplitType] {
        Array(Set(workouts.map(\.split))).sorted { $0.rawValue < $1.rawValue }
    }
}

// MARK: - Sample Data
extension WorkoutProgram {
    static var sampleData: [WorkoutProgram] {
        let push = Workout(name: "Push Day", split: .push, exercises: [
            Exercise(name: "Bench Press",            sets: 4, reps: "8",       weight: "135 lbs", restSeconds: 120),
            Exercise(name: "Overhead Press",         sets: 3, reps: "10",      weight: "95 lbs",  restSeconds: 90),
            Exercise(name: "Incline Dumbbell Press", sets: 3, reps: "12",      weight: "45 lbs",  restSeconds: 90),
            Exercise(name: "Tricep Pushdowns",       sets: 3, reps: "15",      weight: "50 lbs",  restSeconds: 60),
            Exercise(name: "Lateral Raises",         sets: 4, reps: "15",      weight: "20 lbs",  restSeconds: 60)
        ])

        let pull = Workout(name: "Pull Day", split: .pull, exercises: [
            Exercise(name: "Pull-ups",       sets: 4, reps: "8",  weight: "",         restSeconds: 120),
            Exercise(name: "Barbell Row",    sets: 4, reps: "8",  weight: "135 lbs",  restSeconds: 120),
            Exercise(name: "Lat Pulldown",   sets: 3, reps: "12", weight: "100 lbs",  restSeconds: 90),
            Exercise(name: "Face Pulls",     sets: 3, reps: "15", weight: "40 lbs",   restSeconds: 60),
            Exercise(name: "Bicep Curls",    sets: 3, reps: "12", weight: "30 lbs",   restSeconds: 60)
        ])

        let legs = Workout(name: "Leg Day", split: .legs, exercises: [
            Exercise(name: "Squats",              sets: 5, reps: "5",        weight: "185 lbs", restSeconds: 180),
            Exercise(name: "Romanian Deadlift",   sets: 4, reps: "10",       weight: "135 lbs", restSeconds: 120),
            Exercise(name: "Leg Press",           sets: 3, reps: "15",       weight: "270 lbs", restSeconds: 90),
            Exercise(name: "Walking Lunges",      sets: 3, reps: "12 each",  weight: "",        restSeconds: 60),
            Exercise(name: "Calf Raises",         sets: 4, reps: "20",       weight: "135 lbs", restSeconds: 45)
        ])

        return [
            WorkoutProgram(
                name: "PPL Program",
                description: "Push / Pull / Legs 6 days per week",
                emoji: "🔥",
                workouts: [push, pull, legs],
                colorHex: "FF6B35"
            )
        ]
    }
}
