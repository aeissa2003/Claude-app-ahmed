import Foundation
import Observation

@Observable
final class DayDashboardViewModel {
    let uid: String
    let day: Date

    var meals: [MealLog] = []
    var userRecipes: [Recipe] = []
    var loadError: String?
    var isLoading: Bool = false

    private let mealRepo: MealLogRepositoryProtocol
    private let recipeRepo: RecipeRepositoryProtocol

    init(
        uid: String,
        day: Date,
        mealRepo: MealLogRepositoryProtocol,
        recipeRepo: RecipeRepositoryProtocol
    ) {
        self.uid = uid
        self.day = day
        self.mealRepo = mealRepo
        self.recipeRepo = recipeRepo
    }

    // MARK: - Derived

    var consumed: Macros {
        meals.reduce(.zero) { $0 + $1.computedMacros }
    }

    func mealsOfType(_ type: MealType) -> [MealLog] {
        meals.filter { $0.mealType == type }
    }

    /// Top protein-fit recipe suggestions for the remaining protein target.
    func suggestions(proteinGoalG: Double, limit: Int = 3) -> [RecipeSuggestion.Scored] {
        let remaining = max(proteinGoalG - consumed.proteinG, 0)
        return Array(
            RecipeSuggestion.rank(recipes: userRecipes, remainingProteinG: remaining)
                .prefix(limit)
        )
    }

    // MARK: - Loading

    func subscribeMeals() async {
        do {
            for try await list in mealRepo.listStream(ownerUid: uid, on: day) {
                meals = list
            }
        } catch {
            loadError = error.localizedDescription
        }
    }

    func subscribeRecipes() async {
        do {
            for try await list in recipeRepo.listStream(ownerUid: uid) {
                userRecipes = list
            }
        } catch {
            // Non-fatal — suggestions simply won't show.
            userRecipes = []
        }
    }

    func delete(_ log: MealLog) async {
        do {
            try await mealRepo.delete(ownerUid: uid, id: log.id)
        } catch {
            loadError = error.localizedDescription
        }
    }
}
