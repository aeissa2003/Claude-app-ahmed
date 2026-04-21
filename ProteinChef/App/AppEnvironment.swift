import Foundation
import Observation

@Observable
final class AppEnvironment {
    let auth: AuthServiceProtocol
    let firestore: FirestoreServiceProtocol
    let storage: StorageServiceProtocol
    let push: PushServiceProtocol
    let userProfiles: UserProfileRepositoryProtocol

    init(
        auth: AuthServiceProtocol,
        firestore: FirestoreServiceProtocol,
        storage: StorageServiceProtocol,
        push: PushServiceProtocol,
        userProfiles: UserProfileRepositoryProtocol
    ) {
        self.auth = auth
        self.firestore = firestore
        self.storage = storage
        self.push = push
        self.userProfiles = userProfiles
    }

    static func live() -> AppEnvironment {
        AppEnvironment(
            auth: FirebaseAuthService(),
            firestore: FirebaseFirestoreService(),
            storage: FirebaseStorageService(),
            push: FirebasePushService(),
            userProfiles: FirebaseUserProfileRepository()
        )
    }
}
