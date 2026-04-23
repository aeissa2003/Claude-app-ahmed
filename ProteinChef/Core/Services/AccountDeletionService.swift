import Foundation
import FirebaseFirestore

/// Orchestrates "delete my account" from the Settings screen. Required by Apple's
/// App Store guideline 5.1.1(v) for any app that supports account creation.
///
/// Best-effort cleanup: wipes the user's Firestore data and releases their handle,
/// then deletes the Firebase Auth user. If the auth delete fails because the
/// session is stale, the caller is asked to sign in again and retry.
protocol AccountDeletionServiceProtocol: Sendable {
    func deleteAccount(uid: String, handle: String) async throws
}

final class AccountDeletionService: AccountDeletionServiceProtocol, @unchecked Sendable {
    private let db = Firestore.firestore()
    private let auth: AuthServiceProtocol

    init(auth: AuthServiceProtocol) {
        self.auth = auth
    }

    func deleteAccount(uid: String, handle: String) async throws {
        // 1. Release the handle reservation so the name is freed up.
        if !handle.isEmpty {
            try? await db.collection("handles").document(handle).delete()
        }

        // 2. Delete the user's document and known subcollections. Client can only
        //    delete docs it owns; Cloud Functions deploy (Phase 8 doc) recursively
        //    clean up things the client can't reach (e.g. friendships on other
        //    users' collections, feed posts fan-out).
        try? await deleteSubcollection(path: "users/\(uid)/recipes")
        try? await deleteSubcollection(path: "users/\(uid)/mealLogs")
        try? await deleteSubcollection(path: "users/\(uid)/workouts")
        try? await deleteSubcollection(path: "users/\(uid)/workoutTemplates")
        try? await deleteSubcollection(path: "users/\(uid)/customIngredients")
        try? await deleteSubcollection(path: "users/\(uid)/customExercises")
        try? await deleteSubcollection(path: "users/\(uid)/friends")
        try? await deleteSubcollection(path: "users/\(uid)/friendRequests")
        try? await deleteSubcollection(path: "users/\(uid)/sentRequests")
        try? await deleteSubcollection(path: "users/\(uid)/notifications")

        try? await db.collection("users").document(uid).delete()

        // 3. Finally delete the Firebase Auth user. If this requires a recent
        //    login, propagate the error so the UI can prompt re-auth.
        try await auth.deleteCurrentUser()
    }

    private func deleteSubcollection(path: String) async throws {
        let ref = db.collection(path)
        // Client SDK can't recursively delete — page through and batch-delete.
        var lastDoc: DocumentSnapshot?
        repeat {
            var query = ref.limit(to: 100)
            if let lastDoc { query = query.start(afterDocument: lastDoc) }
            let snap = try await query.getDocuments()
            if snap.documents.isEmpty { break }
            let batch = db.batch()
            snap.documents.forEach { batch.deleteDocument($0.reference) }
            try await batch.commit()
            lastDoc = snap.documents.last
            if snap.documents.count < 100 { break }
        } while true
    }
}
