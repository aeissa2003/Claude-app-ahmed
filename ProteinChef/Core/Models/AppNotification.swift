import Foundation

/// Stored at users/{uid}/notifications/{notificationId}.
/// The client subscribes to this collection for an in-app inbox; Cloud Functions
/// also dispatch a matching APNs push using the fcmToken on the user profile.
struct AppNotification: Codable, Identifiable, Hashable, Sendable {
    enum Kind: String, Codable, Sendable {
        case friendRequest          // someone sent you a friend request
        case friendAccepted         // your outgoing request was accepted
        case newFeedPost            // a friend shared a new recipe
        case feedLike               // someone liked your post
        case feedComment            // someone commented on your post
    }

    var id: String
    var kind: Kind
    var title: String
    var body: String
    /// Uid of the person who triggered the notification. Used for deep-linking.
    var actorUid: String
    var actorHandle: String
    var actorDisplayName: String
    var actorPhotoURL: URL?
    /// Post/recipe id for feed notifications; friend uid for friend notifications.
    var targetId: String?
    var read: Bool
    var createdAt: Date
}
