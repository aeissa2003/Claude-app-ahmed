import Foundation

enum Sex: String, Codable, CaseIterable, Sendable {
    case male, female, other, preferNotToSay
}

enum FitnessGoal: String, Codable, CaseIterable, Sendable {
    case cut, maintain, bulk
}

enum DietaryRestriction: String, Codable, CaseIterable, Sendable {
    case vegetarian, vegan, pescatarian, halal, kosher, glutenFree, dairyFree, nutFree
}

enum UnitsPreference: String, Codable, CaseIterable, Sendable {
    case metric, imperial
}

struct UserProfile: Codable, Identifiable, Sendable {
    var id: String                 // Firebase UID
    var displayName: String
    var handle: String             // unique, lowercased
    var email: String?
    var photoURL: URL?

    var sex: Sex
    var age: Int
    var heightCm: Double
    var weightKg: Double
    var goal: FitnessGoal
    var dietaryRestrictions: [DietaryRestriction]

    var proteinGoalG: Double
    var calorieGoalKcal: Double
    var unitsPref: UnitsPreference

    var createdAt: Date
    var updatedAt: Date
    var onboardingCompletedAt: Date?
}

extension UserProfile {
    var isOnboarded: Bool { onboardingCompletedAt != nil }
}
