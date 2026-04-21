import Foundation

/// One set within a workout — weight and reps logged individually per set as requested.
struct WorkoutSet: Codable, Hashable, Sendable, Identifiable {
    var id: String
    var order: Int
    var weightKg: Double              // canonical kg; converted for display
    var reps: Int
    var completed: Bool
}

struct WorkoutExercise: Codable, Hashable, Sendable, Identifiable {
    var id: String
    var exerciseId: String
    var exerciseName: String          // denormalized
    var isCustom: Bool
    var order: Int
    var sets: [WorkoutSet]
    var notes: String?
}

struct Workout: Codable, Identifiable, Sendable {
    var id: String
    var ownerUid: String
    var startedAt: Date
    var endedAt: Date?
    var templateId: String?
    var templateName: String?
    var exercises: [WorkoutExercise]
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
}

struct WorkoutTemplateExercise: Codable, Hashable, Sendable, Identifiable {
    var id: String
    var exerciseId: String
    var exerciseName: String
    var isCustom: Bool
    var order: Int
    var targetSets: Int
    var targetReps: Int
}

struct WorkoutTemplate: Codable, Identifiable, Sendable {
    var id: String
    var ownerUid: String
    var name: String
    var exercises: [WorkoutTemplateExercise]
    var createdAt: Date
    var updatedAt: Date
}
