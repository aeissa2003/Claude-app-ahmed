import Foundation
import UIKit

protocol PushServiceProtocol: Sendable {
    func requestAuthorization() async -> Bool
    func registerForRemoteNotifications()

    /// Called from AppDelegate.MessagingDelegate when FCM yields a token.
    /// Persists it on the current user's profile so Cloud Functions can fan out pushes.
    func updateFCMToken(_ token: String?, forUid uid: String) async
}
