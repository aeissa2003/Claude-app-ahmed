import Foundation
import FirebaseFirestore

final class FirebaseNotificationRepository: NotificationRepositoryProtocol, @unchecked Sendable {
    private let db = Firestore.firestore()

    private func collection(_ uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("notifications")
    }

    func listStream(uid: String) -> AsyncThrowingStream<[AppNotification], Error> {
        AsyncThrowingStream { continuation in
            let listener = collection(uid)
                .order(by: "createdAt", descending: true)
                .limit(to: 200)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: error)
                        return
                    }
                    guard let snapshot else { return }
                    do {
                        let items = try snapshot.documents.map { try $0.data(as: AppNotification.self) }
                        continuation.yield(items)
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
            continuation.onTermination = { _ in listener.remove() }
        }
    }

    func unreadCountStream(uid: String) -> AsyncThrowingStream<Int, Error> {
        AsyncThrowingStream { continuation in
            let listener = collection(uid)
                .whereField("read", isEqualTo: false)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: error)
                        return
                    }
                    continuation.yield(snapshot?.documents.count ?? 0)
                }
            continuation.onTermination = { _ in listener.remove() }
        }
    }

    func markRead(uid: String, notificationId: String) async throws {
        try await collection(uid).document(notificationId).updateData(["read": true])
    }

    func markAllRead(uid: String) async throws {
        let snapshot = try await collection(uid)
            .whereField("read", isEqualTo: false)
            .getDocuments()
        let batch = db.batch()
        for doc in snapshot.documents {
            batch.updateData(["read": true], forDocument: doc.reference)
        }
        try await batch.commit()
    }

    func delete(uid: String, notificationId: String) async throws {
        try await collection(uid).document(notificationId).delete()
    }
}
