import Foundation

/// A snapshot of a recipe as it existed when posted — so edits to the source recipe
/// don't retroactively change what friends saw in their feed.
struct RecipeSnapshot: Codable, Hashable, Sendable {
    var recipeId: String
    var title: String
    var coverPhotoURL: URL?
    var macrosPerServing: Macros
    var servings: Double
    var prepMinutes: Int
    var cookMinutes: Int
    var isHighProtein: Bool
}

struct FeedPost: Codable, Identifiable, Sendable {
    var id: String
    var authorUid: String
    var authorHandle: String
    var authorDisplayName: String
    var authorPhotoURL: URL?
    var recipeSnapshot: RecipeSnapshot
    var caption: String?
    var likeCount: Int
    var commentCount: Int
    var createdAt: Date
}

struct FeedComment: Codable, Identifiable, Sendable {
    var id: String
    var authorUid: String
    var authorHandle: String
    var authorDisplayName: String
    var authorPhotoURL: URL?
    var text: String
    var createdAt: Date
}

struct FeedLike: Codable, Identifiable, Sendable {
    var id: String                  // liker uid
    var createdAt: Date
}
