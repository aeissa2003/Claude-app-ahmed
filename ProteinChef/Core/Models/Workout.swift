import Foundation

/// One set within a workout. Fields populated depend on the parent exercise's kind:
/// - strength: weightKg + reps
/// - bodyweight: reps (weightKg may be 0 or absent)
/// - cardio: durationSeconds, optional distanceM
struct WorkoutSet: Codable, Hashable, Sendable, Identifiable {
    var id: String
    var order: Int
    var weightKg: Double?             // canonical kg; nil/zero for bodyweight or cardio
    var reps: Int?                    // nil for cardio
    var durationSeconds: Int?         // for cardio
    var distanceM: Double?            // for cardio, optional
    var completed: Bool
}

struct WorkoutExercise: Codable, Hashable, Sendable, Identifiable {
    var id: String
    var exerciseId: String
    var exerciseName: String          // denormalized
    var isCustom: Bool
    var kind: ExerciseKind            // persisted so the UI knows which fields to show
    var order: Int
    var sets: [WorkoutSet]
    var notes: String?
}

struct Workout: Codable, Identifiable, Hashable, Sendable {
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
    var kind: ExerciseKind
    var order: Int
    var targetSets: Int
    var targetReps: Int?              // nil for cardio
    var targetDurationSeconds: Int?   // for cardio
}

struct WorkoutTemplate: Codable, Identifiable, Hashable, Sendable {
    var id: String
    var ownerUid: String
    var name: String
    var exercises: [WorkoutTemplateExercise]
    var createdAt: Date
    var updatedAt: Date
}
