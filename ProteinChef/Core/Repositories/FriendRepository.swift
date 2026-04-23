import Foundation

/// Relationship between the current user and another user, for rendering
/// the right action button (send/accept/pending/unfriend) in the UI.
enum FriendRelation: Equatable, Sendable {
    case self_
    case none
    case outgoingPending
    case incomingPending
    case friends
}

protocol FriendRepositoryProtocol: Sendable {
    /// Exact-match handle lookup: /handles/{handle} -> uid -> users/{uid} profile.
    func lookupByHandle(_ handle: String) async throws -> UserProfile?

    func listFriendsStream(uid: String) -> AsyncThrowingStream<[Friendship], Error>
    func listIncomingRequestsStream(uid: String) -> AsyncThrowingStream<[FriendRequest], Error>
    func listSentRequestsStream(uid: String) -> AsyncThrowingStream<[SentRequest], Error>

    /// Checks the relation between `me` and `other`, used by the search result row.
    func relation(meUid: String, otherUid: String) async throws -> FriendRelation

    func sendRequest(me: UserProfile, toUid: String, toHandle: String) async throws
    func cancelSentRequest(meUid: String, toUid: String) async throws
    func acceptRequest(me: UserProfile, fromUid: String) async throws
    func declineRequest(meUid: String, fromUid: String) async throws
    func unfriend(meUid: String, friendUid: String) async throws
}
