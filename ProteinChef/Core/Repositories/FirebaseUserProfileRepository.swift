import Foundation
import FirebaseFirestore

final class FirebaseUserProfileRepository: UserProfileRepositoryProtocol, @unchecked Sendable {
    private let db = Firestore.firestore()

    private func userDoc(_ uid: String) -> DocumentReference {
        db.collection("users").document(uid)
    }

    private func handleDoc(_ handle: String) -> DocumentReference {
        db.collection("handles").document(handle.lowercased())
    }

    func fetch(uid: String) async throws -> UserProfile? {
        let snapshot = try await userDoc(uid).getDocument()
        guard snapshot.exists else { return nil }
        return try snapshot.data(as: UserProfile.self)
    }

    func save(_ profile: UserProfile) async throws {
        try userDoc(profile.id).setData(from: profile, merge: true)
    }

    func isHandleAvailable(_ handle: String) async throws -> Bool {
        guard HandleValidator.isValid(handle) else { throw HandleError.invalidFormat }
        let doc = try await handleDoc(handle).getDocument()
        return !doc.exists
    }

    func reserveHandle(_ handle: String, uid: String) async throws {
        guard HandleValidator.isValid(handle) else { throw HandleError.invalidFormat }
        let normalized = HandleValidator.normalize(handle)
        let ref = handleDoc(normalized)
        _ = try await db.runTransaction { tx, errorPointer in
            do {
                let snap = try tx.getDocument(ref)
                if snap.exists {
                    errorPointer?.pointee = HandleError.alreadyTaken as NSError
                    return nil
                }
                tx.setData(["uid": uid, "createdAt": FieldValue.serverTimestamp()], forDocument: ref)
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }

    func changeHandle(from oldHandle: String?, to newHandle: String, uid: String) async throws {
        guard HandleValidator.isValid(newHandle) else { throw HandleError.invalidFormat }
        let normalized = HandleValidator.normalize(newHandle)
        let newRef = handleDoc(normalized)
        let oldRef = oldHandle.map { handleDoc(HandleValidator.normalize($0)) }
        _ = try await db.runTransaction { tx, errorPointer in
            do {
                let snap = try tx.getDocument(newRef)
                if snap.exists, snap.data()?["uid"] as? String != uid {
                    errorPointer?.pointee = HandleError.alreadyTaken as NSError
                    return nil
                }
                tx.setData(["uid": uid, "createdAt": FieldValue.serverTimestamp()], forDocument: newRef)
                if let oldRef, oldRef.path != newRef.path {
                    tx.deleteDocument(oldRef)
                }
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }
}
