import Foundation
import FirebaseFirestore

final class FirebaseFriendRepository: FriendRepositoryProtocol, @unchecked Sendable {
    private let db = Firestore.firestore()

    // MARK: - Lookup

    func lookupByHandle(_ handle: String) async throws -> UserProfile? {
        let normalized = HandleValidator.normalize(handle)
        guard HandleValidator.isValid(normalized) else { return nil }
        let handleDoc = try await db.collection("handles").document(normalized).getDocument()
        guard let uid = handleDoc.data()? ["uid"] as? String else { return nil }
        let userDoc = try await db.collection("users").document(uid).getDocument()
        guard userDoc.exists else { return nil }
        return try userDoc.data(as: UserProfile.self)
    }

    // MARK: - Streams

    func listFriendsStream(uid: String) -> AsyncThrowingStream<[Friendship], Error> {
        stream(collection: db.collection("users").document(uid).collection("friends"))
    }

    func listIncomingRequestsStream(uid: String) -> AsyncThrowingStream<[FriendRequest], Error> {
        stream(collection: db.collection("users").document(uid).collection("friendRequests"))
    }

    func listSentRequestsStream(uid: String) -> AsyncThrowingStream<[SentRequest], Error> {
        stream(collection: db.collection("users").document(uid).collection("sentRequests"))
    }

    private func stream<T: Decodable>(collection: CollectionReference) -> AsyncThrowingStream<[T], Error> {
        AsyncThrowingStream { continuation in
            let listener = collection.addSnapshotListener { snapshot, error in
                if let error {
                    continuation.finish(throwing: error)
                    return
                }
                guard let snapshot else { return }
                do {
                    let items = try snapshot.documents.map { try $0.data(as: T.self) }
                    continuation.yield(items)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in listener.remove() }
        }
    }

    // MARK: - Relation

    func relation(meUid: String, otherUid: String) async throws -> FriendRelation {
        if meUid == otherUid { return .self_ }
        let friendsRef = db.collection("users").document(meUid).collection("friends").document(otherUid)
        if try await friendsRef.getDocument().exists { return .friends }
        let sentRef = db.collection("users").document(meUid).collection("sentRequests").document(otherUid)
        if try await sentRef.getDocument().exists { return .outgoingPending }
        let incomingRef = db.collection("users").document(meUid).collection("friendRequests").document(otherUid)
        if try await incomingRef.getDocument().exists { return .incomingPending }
        return .none
    }

    // MARK: - Mutations

    func sendRequest(me: UserProfile, toUid: String, toHandle: String) async throws {
        let batch = db.batch()
        let now = Date()

        let incomingRef = db.collection("users").document(toUid)
            .collection("friendRequests").document(me.id)
        let incoming = FriendRequest(
            id: me.id,
            fromHandle: me.handle,
            fromDisplayName: me.displayName,
            fromPhotoURL: me.photoURL,
            createdAt: now
        )
        try batch.setData(from: incoming, forDocument: incomingRef)

        let sentRef = db.collection("users").document(me.id)
            .collection("sentRequests").document(toUid)
        let sent = SentRequest(id: toUid, toHandle: toHandle, createdAt: now)
        try batch.setData(from: sent, forDocument: sentRef)

        try await batch.commit()
    }

    func cancelSentRequest(meUid: String, toUid: String) async throws {
        let batch = db.batch()
        batch.deleteDocument(
            db.collection("users").document(meUid).collection("sentRequests").document(toUid)
        )
        batch.deleteDocument(
            db.collection("users").document(toUid).collection("friendRequests").document(meUid)
        )
        try await batch.commit()
    }

    func acceptRequest(me: UserProfile, fromUid: String) async throws {
        // Load the incoming request doc so we have the requester's denormalized info.
        let incomingRef = db.collection("users").document(me.id)
            .collection("friendRequests").document(fromUid)
        let incomingDoc = try await incomingRef.getDocument()
        guard let incoming = try? incomingDoc.data(as: FriendRequest.self) else {
            throw NSError(domain: "Friend", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Request no longer exists."])
        }

        let batch = db.batch()
        let now = Date()

        // My friend doc pointing at them.
        let myFriend = Friendship(
            id: fromUid,
            friendHandle: incoming.fromHandle,
            friendDisplayName: incoming.fromDisplayName,
            friendPhotoURL: incoming.fromPhotoURL,
            status: .accepted,
            since: now
        )
        try batch.setData(from: myFriend,
                          forDocument: db.collection("users").document(me.id)
                              .collection("friends").document(fromUid))

        // Their friend doc pointing at me.
        let theirFriend = Friendship(
            id: me.id,
            friendHandle: me.handle,
            friendDisplayName: me.displayName,
            friendPhotoURL: me.photoURL,
            status: .accepted,
            since: now
        )
        try batch.setData(from: theirFriend,
                          forDocument: db.collection("users").document(fromUid)
                              .collection("friends").document(me.id))

        batch.deleteDocument(incomingRef)
        batch.deleteDocument(
            db.collection("users").document(fromUid).collection("sentRequests").document(me.id)
        )
        try await batch.commit()
    }

    func declineRequest(meUid: String, fromUid: String) async throws {
        let batch = db.batch()
        batch.deleteDocument(
            db.collection("users").document(meUid).collection("friendRequests").document(fromUid)
        )
        batch.deleteDocument(
            db.collection("users").document(fromUid).collection("sentRequests").document(meUid)
        )
        try await batch.commit()
    }

    func unfriend(meUid: String, friendUid: String) async throws {
        let batch = db.batch()
        batch.deleteDocument(
            db.collection("users").document(meUid).collection("friends").document(friendUid)
        )
        batch.deleteDocument(
            db.collection("users").document(friendUid).collection("friends").document(meUid)
        )
        try await batch.commit()
    }
}
