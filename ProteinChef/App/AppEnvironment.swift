import Foundation
import Observation

@Observable
final class AppEnvironment {
    let auth: AuthServiceProtocol
    let firestore: FirestoreServiceProtocol
    let storage: StorageServiceProtocol
    let push: PushServiceProtocol

    init(
        auth: AuthServiceProtocol,
        firestore: FirestoreServiceProtocol,
        storage: StorageServiceProtocol,
        push: PushServiceProtocol
    ) {
        self.auth = auth
        self.firestore = firestore
        self.storage = storage
        self.push = push
    }

    static func live() -> AppEnvironment {
        AppEnvironment(
            auth: FirebaseAuthService(),
            firestore: FirebaseFirestoreService(),
            storage: FirebaseStorageService(),
            push: FirebasePushService()
        )
    }
}
