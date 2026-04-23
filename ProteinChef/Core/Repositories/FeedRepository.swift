import Foundation

protocol FeedRepositoryProtocol: Sendable {
    /// Stream posts authored by the given uids (i.e. the user's friends) sorted
    /// newest-first. Firestore `in` queries cap at 30 values so friendUids is
    /// chunked into pages transparently by the implementation.
    func listFriendsFeedStream(friendUids: [String]) -> AsyncThrowingStream<[FeedPost], Error>

    func sharePost(author: UserProfile, recipe: Recipe, caption: String?) async throws -> FeedPost
    func deletePost(postId: String) async throws

    /// Returns true if the post is now liked by the user (i.e. the like was added).
    func toggleLike(postId: String, likerUid: String) async throws -> Bool
    func hasLiked(postId: String, likerUid: String) async throws -> Bool

    func listCommentsStream(postId: String) -> AsyncThrowingStream<[FeedComment], Error>
    func addComment(postId: String, author: UserProfile, text: String) async throws
    func deleteComment(postId: String, commentId: String) async throws
}
