import Foundation

enum RecipePrivacy: String, Codable, Sendable {
    case `private`
    case shared
}

struct RecipeStep: Codable, Hashable, Sendable, Identifiable {
    var id: String
    var order: Int
    var text: String
}

struct Recipe: Codable, Identifiable, Sendable {
    var id: String
    var ownerUid: String
    var title: String
    var coverPhotoURL: URL?
    var galleryPhotoURLs: [URL]
    var instructions: [RecipeStep]
    var prepMinutes: Int
    var cookMinutes: Int
    var servings: Double
    var tags: [String]
    var ingredients: [RecipeIngredient]

    var macrosTotal: Macros
    var macrosPerServing: Macros
    var isHighProtein: Bool          // computed: perServing.proteinG >= threshold (default 30)

    var privacy: RecipePrivacy
    var sourceRecipeId: String?      // if this was saved as a copy from a friend
    var sourceUserId: String?
    var sourceUserHandle: String?    // denormalized for "adapted from @friend" attribution

    var createdAt: Date
    var updatedAt: Date
}
