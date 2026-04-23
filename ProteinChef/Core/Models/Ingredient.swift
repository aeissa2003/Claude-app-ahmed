import Foundation

enum IngredientCategory: String, Codable, CaseIterable, Sendable {
    case meat, poultry, seafood, dairy, eggs, legumes, grains, vegetables, fruits, nutsAndSeeds, fatsAndOils, condiments, beverages, supplements, other
}

/// A "portion" the user can pick when adding this ingredient to a recipe.
/// `grams` is how many grams one of this portion weighs.
/// Grams and ounces are always available implicitly and are not listed here.
struct UnitPortion: Codable, Hashable, Sendable {
    var label: String           // "piece", "cup", "tbsp", "tsp", "medium", "slice"
    var grams: Double
}

/// A global, read-only catalog ingredient.
struct Ingredient: Codable, Identifiable, Hashable, Sendable {
    var id: String
    var name: String
    var aliases: [String]
    var category: IngredientCategory
    var stockPhotoURL: URL?
    var macrosPer100g: Macros
    var commonUnits: [UnitPortion]?
}

/// An ingredient entry on a specific recipe — with the quantity used and an optional user-shot photo.
struct RecipeIngredient: Codable, Identifiable, Hashable, Sendable {
    var id: String                   // client-generated UUID string
    var ingredientId: String         // references Ingredient.id or CustomIngredient.id
    var ingredientName: String       // denormalized for offline display
    var isCustom: Bool               // true if from user's customIngredients
    var quantityG: Double            // canonical grams
    var displayQuantity: Double      // what the user typed (e.g. 1.5)
    var displayUnit: String          // "cup", "tbsp", "oz", "g"...
    var photoURL: URL?               // optional per-recipe photo
    var macrosAtEntry: Macros        // snapshot so historical recipes stay correct if catalog changes
}

/// A user-created ingredient (stored under users/{uid}/customIngredients/{id}).
struct CustomIngredient: Codable, Identifiable, Hashable, Sendable {
    var id: String
    var name: String
    var category: IngredientCategory
    var macrosPer100g: Macros
    var createdAt: Date
}
