import Foundation

protocol NotificationRepositoryProtocol: Sendable {
    /// Stream the user's notifications newest-first.
    func listStream(uid: String) -> AsyncThrowingStream<[AppNotification], Error>

    /// Unread count stream, for badging.
    func unreadCountStream(uid: String) -> AsyncThrowingStream<Int, Error>

    func markRead(uid: String, notificationId: String) async throws
    func markAllRead(uid: String) async throws
    func delete(uid: String, notificationId: String) async throws
}
