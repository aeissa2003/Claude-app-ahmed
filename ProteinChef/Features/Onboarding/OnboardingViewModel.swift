import Foundation
import Observation

@Observable
final class OnboardingViewModel {
    let uid: String
    var displayName: String
    let email: String?

    // Basics
    var sex: Sex = .preferNotToSay
    var age: Int = 25
    var heightCm: Double = 175
    var weightKg: Double = 75

    // Handle
    var handle: String = ""
    var handleCheckState: HandleCheckState = .idle

    // Goal
    var goal: FitnessGoal = .maintain

    // Diet
    var diet: Set<DietaryRestriction> = []

    // Protein target
    var proteinGoalG: Double = 140         // placeholder; recomputed on entering step

    // Units (default metric; user can change in settings later)
    var unitsPref: UnitsPreference = .metric

    // UI
    var isSaving = false
    var errorText: String?

    init(uid: String, displayName: String, email: String?) {
        self.uid = uid
        self.displayName = displayName
        self.email = email
    }

    enum HandleCheckState: Equatable {
        case idle, checking, available, taken, invalid
    }

    var computedProteinGoal: Double {
        MacroMath.recommendedProteinGoal(bodyweightKg: weightKg, goal: goal)
    }

    var computedCalorieGoal: Double {
        MacroMath.recommendedCalorieGoal(
            sex: sex,
            age: age,
            heightCm: heightCm,
            weightKg: weightKg,
            goal: goal
        )
    }

    func profileSnapshot() -> UserProfile {
        let now = Date()
        return UserProfile(
            id: uid,
            displayName: displayName,
            handle: HandleValidator.normalize(handle),
            email: email,
            photoURL: nil,
            sex: sex,
            age: age,
            heightCm: heightCm,
            weightKg: weightKg,
            goal: goal,
            dietaryRestrictions: Array(diet),
            proteinGoalG: proteinGoalG,
            calorieGoalKcal: computedCalorieGoal,
            unitsPref: unitsPref,
            createdAt: now,
            updatedAt: now,
            onboardingCompletedAt: now
        )
    }
}
