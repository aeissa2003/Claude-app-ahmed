import Foundation

enum MealType: String, Codable, CaseIterable, Sendable {
    case breakfast, lunch, dinner, snack
}

/// Ad-hoc entry when the user logs a food that isn't one of their saved recipes.
struct AdHocFood: Codable, Hashable, Sendable {
    var name: String
    var matchedIngredientId: String?  // optional — if auto-filled from ingredient DB
    var quantityG: Double
    var macros: Macros
}

struct MealLog: Codable, Identifiable, Sendable {
    var id: String
    var ownerUid: String
    var date: Date                    // stored at noon local time to dodge timezone edge cases
    var mealType: MealType

    // Either/or: the log references a recipe OR contains ad-hoc data.
    var recipeId: String?
    var recipeTitleSnapshot: String?
    var servings: Double?

    var adHoc: AdHocFood?

    var computedMacros: Macros        // denormalized for the dashboard
    var createdAt: Date
}
