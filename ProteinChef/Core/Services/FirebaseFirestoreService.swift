import Foundation
import FirebaseFirestore

final class FirebaseFirestoreService: FirestoreServiceProtocol, @unchecked Sendable {
    private let db = Firestore.firestore()

    init() {
        let settings = db.settings
        settings.isPersistenceEnabled = true
        db.settings = settings
    }

    func ping() async throws {
        _ = try await db.collection("_ping").limit(to: 1).getDocuments()
    }
}
