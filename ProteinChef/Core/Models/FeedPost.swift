import Foundation

/// A post on the friends feed. Embeds the full Recipe so friends can save a copy
/// without a second read, and the recipe displayed in the feed stays fixed even
/// if the author later edits the source.
struct FeedPost: Codable, Identifiable, Hashable, Sendable {
    var id: String
    var authorUid: String
    var authorHandle: String
    var authorDisplayName: String
    var authorPhotoURL: URL?
    var recipe: Recipe              // snapshot at time of sharing
    var caption: String?
    var likeCount: Int
    var commentCount: Int
    var createdAt: Date
}

struct FeedComment: Codable, Identifiable, Hashable, Sendable {
    var id: String
    var authorUid: String
    var authorHandle: String
    var authorDisplayName: String
    var authorPhotoURL: URL?
    var text: String
    var createdAt: Date
}

struct FeedLike: Codable, Identifiable, Hashable, Sendable {
    var id: String                  // liker uid
    var createdAt: Date
}
