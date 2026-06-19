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

// MARK: - WorkoutSplit (user-defined)
struct WorkoutSplit: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var colorHex: String
    var icon: String

    init(id: UUID = UUID(), name: String, colorHex: String = "FF6B35", icon: String = "tag.fill") {
        self.id       = id
        self.name     = name
        self.colorHex = colorHex
        self.icon     = icon
    }

    var color: Color { Color(hex: colorHex) }

    static let presetColors: [(name: String, hex: String)] = [
        ("Orange", "FF6B35"), ("Red",    "FF3B30"), ("Pink",   "FF2D55"),
        ("Purple", "BF5AF2"), ("Indigo", "5E5CE6"), ("Blue",   "0A84FF"),
        ("Teal",   "4ECDC4"), ("Green",  "30D158"), ("Yellow", "FFD60A"),
        ("Cyan",   "32ADE6"),
    ]

    static let presetIcons = [
        "tag.fill", "dumbbell.fill", "figure.strengthtraining.traditional",
        "heart.fill", "flame.fill", "bolt.fill",
        "figure.run", "figure.walk", "arrow.up.circle.fill",
        "arrow.down.circle.fill", "star.fill", "scope",
    ]
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
        id: UUID = UUID(), name: String = "", sets: Int = 3,
        reps: String = "10", weight: String = "", restSeconds: Int = 60, notes: String = ""
    ) {
        self.id = id; self.name = name; self.sets = sets
        self.reps = reps; self.weight = weight
        self.restSeconds = restSeconds; self.notes = notes
    }

    var displayString: String {
        var parts = ["\(sets) × \(reps)"]
        if !weight.isEmpty { parts.append("@ \(weight)") }
        return parts.joined(separator: " ")
    }

    var restDisplay: String {
        if restSeconds == 0 { return "No rest" }
        if restSeconds < 60 { return "\(restSeconds)s" }
        let m = restSeconds / 60; let s = restSeconds % 60
        return s == 0 ? "\(m)m" : "\(m)m \(s)s"
    }
}

// MARK: - Workout
struct Workout: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var splitID: UUID?
    var exercises: [Exercise]
    var notes: String
    var createdAt: Date

    init(
        id: UUID = UUID(), name: String = "", splitID: UUID? = nil,
        exercises: [Exercise] = [], notes: String = "", createdAt: Date = Date()
    ) {
        self.id = id; self.name = name; self.splitID = splitID
        self.exercises = exercises; self.notes = notes; self.createdAt = createdAt
    }
}

// MARK: - WorkoutProgram
struct WorkoutProgram: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var description: String
    var emoji: String
    var splits: [WorkoutSplit]
    var workouts: [Workout]
    var createdAt: Date
    var colorHex: String

    init(
        id: UUID = UUID(), name: String = "", description: String = "",
        emoji: String = "💪", splits: [WorkoutSplit] = [], workouts: [Workout] = [],
        createdAt: Date = Date(), colorHex: String = "FF6B35"
    ) {
        self.id = id; self.name = name; self.description = description
        self.emoji = emoji; self.splits = splits; self.workouts = workouts
        self.createdAt = createdAt; self.colorHex = colorHex
    }

    var color: Color { Color(hex: colorHex) }
    var totalExercises: Int { workouts.reduce(0) { $0 + $1.exercises.count } }

    func split(for workout: Workout) -> WorkoutSplit? {
        guard let sid = workout.splitID else { return nil }
        return splits.first { $0.id == sid }
    }

    var usedSplits: [WorkoutSplit] {
        let usedIDs = Set(workouts.compactMap(\.splitID))
        return splits.filter { usedIDs.contains($0.id) }
    }
}

// MARK: - Sample Data
extension WorkoutProgram {
    static var sampleData: [WorkoutProgram] {
        let push  = WorkoutSplit(name: "Push",  colorHex: "FF6B35", icon: "arrow.up.circle.fill")
        let pull  = WorkoutSplit(name: "Pull",  colorHex: "4ECDC4", icon: "arrow.down.circle.fill")
        let legs  = WorkoutSplit(name: "Legs",  colorHex: "45B7D1", icon: "figure.walk")

        let pushW = Workout(name: "Push Day", splitID: push.id, exercises: [
            Exercise(name: "Bench Press",            sets: 4, reps: "8",      weight: "135 lbs", restSeconds: 120),
            Exercise(name: "Overhead Press",         sets: 3, reps: "10",     weight: "95 lbs",  restSeconds: 90),
            Exercise(name: "Incline Dumbbell Press", sets: 3, reps: "12",     weight: "45 lbs",  restSeconds: 90),
            Exercise(name: "Tricep Pushdowns",       sets: 3, reps: "15",     weight: "50 lbs",  restSeconds: 60),
            Exercise(name: "Lateral Raises",         sets: 4, reps: "15",     weight: "20 lbs",  restSeconds: 60),
        ])
        let pullW = Workout(name: "Pull Day", splitID: pull.id, exercises: [
            Exercise(name: "Pull-ups",     sets: 4, reps: "8",  weight: "",         restSeconds: 120),
            Exercise(name: "Barbell Row",  sets: 4, reps: "8",  weight: "135 lbs",  restSeconds: 120),
            Exercise(name: "Lat Pulldown", sets: 3, reps: "12", weight: "100 lbs",  restSeconds: 90),
            Exercise(name: "Face Pulls",   sets: 3, reps: "15", weight: "40 lbs",   restSeconds: 60),
            Exercise(name: "Bicep Curls",  sets: 3, reps: "12", weight: "30 lbs",   restSeconds: 60),
        ])
        let legsW = Workout(name: "Leg Day", splitID: legs.id, exercises: [
            Exercise(name: "Squats",            sets: 5, reps: "5",       weight: "185 lbs", restSeconds: 180),
            Exercise(name: "Romanian Deadlift", sets: 4, reps: "10",      weight: "135 lbs", restSeconds: 120),
            Exercise(name: "Leg Press",         sets: 3, reps: "15",      weight: "270 lbs", restSeconds: 90),
            Exercise(name: "Walking Lunges",    sets: 3, reps: "12 each", weight: "",        restSeconds: 60),
            Exercise(name: "Calf Raises",       sets: 4, reps: "20",      weight: "135 lbs", restSeconds: 45),
        ])

        return [WorkoutProgram(
            name: "PPL Program",
            description: "Push / Pull / Legs 6 days per week",
            emoji: "🔥",
            splits: [push, pull, legs],
            workouts: [pushW, pullW, legsW],
            colorHex: "FF6B35"
        )]
    }
}
