import Foundation

/// Ranks recipes for "what should I eat next" based on how well they fit the user's
/// remaining daily protein target. Used by the dashboard and suggestions screens in Phase 4.
enum RecipeSuggestion {
    struct Scored {
        let recipe: Recipe
        let score: Double           // higher = better fit
        let servings: Double        // recommended servings to eat
        let protein: Double         // grams delivered at recommended servings
    }

    /// Score a recipe against remaining protein grams for the day.
    /// The ideal serving size is `remainingProtein / proteinPerServing`, clamped to [0.5, 3].
    /// Score penalizes overshoot more heavily than undershoot.
    static func rank(recipes: [Recipe], remainingProteinG: Double) -> [Scored] {
        guard remainingProteinG > 0 else { return [] }

        let scored: [Scored] = recipes.compactMap { recipe in
            let perServing = recipe.macrosPerServing.proteinG
            guard perServing > 0 else { return nil }

            let idealServings = (remainingProteinG / perServing).clamped(to: 0.5...3)
            let roundedServings = (idealServings * 2).rounded() / 2   // half-servings
            let deliveredProtein = perServing * roundedServings

            let delta = deliveredProtein - remainingProteinG
            let penalty = delta >= 0 ? delta * 1.5 : abs(delta)    // overshoot penalized 1.5×
            let score = 100.0 - penalty
            return Scored(
                recipe: recipe,
                score: score,
                servings: roundedServings,
                protein: deliveredProtein
            )
        }
        return scored.sorted { $0.score > $1.score }
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
