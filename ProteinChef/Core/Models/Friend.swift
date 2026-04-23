import Foundation

enum FriendshipStatus: String, Codable, Sendable {
    case pending, accepted, blocked
}

/// A document at users/{uid}/friends/{friendUid}.
/// Stored symmetrically on both users' subcollections once accepted.
struct Friendship: Codable, Identifiable, Hashable, Sendable {
    var id: String                  // friendUid
    var friendHandle: String
    var friendDisplayName: String
    var friendPhotoURL: URL?
    var status: FriendshipStatus
    var since: Date
}

/// Incoming request at users/{uid}/friendRequests/{fromUid}.
struct FriendRequest: Codable, Identifiable, Hashable, Sendable {
    var id: String                  // fromUid
    var fromHandle: String
    var fromDisplayName: String
    var fromPhotoURL: URL?
    var createdAt: Date
}

/// Outgoing request at users/{uid}/sentRequests/{toUid}. Lightweight — exists to
/// show pending-state in the UI when searching for users.
struct SentRequest: Codable, Identifiable, Hashable, Sendable {
    var id: String                  // toUid
    var toHandle: String
    var createdAt: Date
}
