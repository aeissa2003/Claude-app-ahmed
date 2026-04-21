import Foundation

enum MacroMath {
    /// Default threshold (g of protein per serving) for the "high protein" badge.
    static let defaultHighProteinThresholdG: Double = 30

    /// Compute macros for a single recipe-ingredient entry from its grams and per-100g macros.
    static func macros(forGrams grams: Double, per100g: Macros) -> Macros {
        per100g * (grams / 100.0)
    }

    /// Sum ingredient macros into a recipe total.
    static func total(of ingredients: [RecipeIngredient]) -> Macros {
        ingredients.reduce(.zero) { $0 + $1.macrosAtEntry }
    }

    static func perServing(total: Macros, servings: Double) -> Macros {
        guard servings > 0 else { return .zero }
        return total * (1.0 / servings)
    }

    static func isHighProtein(perServing: Macros, threshold: Double = defaultHighProteinThresholdG) -> Bool {
        perServing.proteinG >= threshold
    }

    /// Recommend a daily protein target in grams from bodyweight + goal.
    /// Cut: 2.2 g/kg, Maintain: 1.8 g/kg, Bulk: 1.6 g/kg. Rounded to nearest 5 g.
    static func recommendedProteinGoal(bodyweightKg: Double, goal: FitnessGoal) -> Double {
        let factor: Double = switch goal {
        case .cut:      2.2
        case .maintain: 1.8
        case .bulk:     1.6
        }
        return (bodyweightKg * factor / 5).rounded() * 5
    }

    /// Very rough calorie target: Mifflin–St Jeor BMR × 1.55 activity, adjusted for goal.
    /// This is a starting point; users can override.
    static func recommendedCalorieGoal(
        sex: Sex,
        age: Int,
        heightCm: Double,
        weightKg: Double,
        goal: FitnessGoal
    ) -> Double {
        let bmr: Double = switch sex {
        case .male:
            10 * weightKg + 6.25 * heightCm - 5 * Double(age) + 5
        case .female:
            10 * weightKg + 6.25 * heightCm - 5 * Double(age) - 161
        case .other, .preferNotToSay:
            10 * weightKg + 6.25 * heightCm - 5 * Double(age) - 78   // midpoint
        }
        let tdee = bmr * 1.55
        let adjusted: Double = switch goal {
        case .cut:      tdee - 400
        case .maintain: tdee
        case .bulk:     tdee + 300
        }
        return (adjusted / 10).rounded() * 10
    }
}
