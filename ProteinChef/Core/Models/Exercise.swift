import Foundation

enum MuscleGroup: String, Codable, CaseIterable, Sendable {
    case chest, back, shoulders, biceps, triceps, forearms
    case quads, hamstrings, glutes, calves, core, fullBody
    case cardio
}

enum Equipment: String, Codable, CaseIterable, Sendable {
    case barbell, dumbbell, kettlebell, machine, cable, bodyweight, band, treadmill, bike, rower, other
}

/// What fields a set of this exercise expects.
/// - strength: weight + reps
/// - bodyweight: reps only
/// - cardio: duration (seconds) + optional distance (meters)
enum ExerciseKind: String, Codable, CaseIterable, Sendable {
    case strength
    case bodyweight
    case cardio
}

/// Global, read-only catalog exercise.
struct Exercise: Codable, Identifiable, Hashable, Sendable {
    var id: String
    var name: String
    var primaryMuscle: MuscleGroup
    var secondaryMuscles: [MuscleGroup]
    var equipment: Equipment
    var stockPhotoURL: URL?
    var kind: ExerciseKind?              // defaults to strength when absent in older seed data

    var resolvedKind: ExerciseKind {
        if let kind { return kind }
        if equipment == .bodyweight { return .bodyweight }
        return .strength
    }
}

struct CustomExercise: Codable, Identifiable, Hashable, Sendable {
    var id: String
    var name: String
    var primaryMuscle: MuscleGroup
    var secondaryMuscles: [MuscleGroup]
    var equipment: Equipment
    var kind: ExerciseKind?
    var createdAt: Date

    var resolvedKind: ExerciseKind {
        if let kind { return kind }
        if equipment == .bodyweight { return .bodyweight }
        return .strength
    }
}
