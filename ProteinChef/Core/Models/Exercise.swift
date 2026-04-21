import Foundation

enum MuscleGroup: String, Codable, CaseIterable, Sendable {
    case chest, back, shoulders, biceps, triceps, forearms
    case quads, hamstrings, glutes, calves, core, fullBody
}

enum Equipment: String, Codable, CaseIterable, Sendable {
    case barbell, dumbbell, kettlebell, machine, cable, bodyweight, band, other
}

/// Global, read-only catalog exercise.
struct Exercise: Codable, Identifiable, Hashable, Sendable {
    var id: String
    var name: String
    var primaryMuscle: MuscleGroup
    var secondaryMuscles: [MuscleGroup]
    var equipment: Equipment
    var stockPhotoURL: URL?
}

struct CustomExercise: Codable, Identifiable, Hashable, Sendable {
    var id: String
    var name: String
    var primaryMuscle: MuscleGroup
    var secondaryMuscles: [MuscleGroup]
    var equipment: Equipment
    var createdAt: Date
}
