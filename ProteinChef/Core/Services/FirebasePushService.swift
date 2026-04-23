import Foundation
import UIKit
import UserNotifications
import FirebaseFirestore

final class FirebasePushService: PushServiceProtocol, @unchecked Sendable {
    private let db = Firestore.firestore()

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func registerForRemoteNotifications() {
        Task { @MainActor in
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    func updateFCMToken(_ token: String?, forUid uid: String) async {
        guard !uid.isEmpty else { return }
        let data: [String: Any] = [
            "fcmToken": token as Any,
            "fcmTokenUpdatedAt": FieldValue.serverTimestamp()
        ]
        do {
            try await db.collection("users").document(uid).setData(data, merge: true)
        } catch {
            // Swallow — token will be retried on next app launch via MessagingDelegate.
            #if DEBUG
            print("Failed to persist FCM token: \(error.localizedDescription)")
            #endif
        }
    }
}
