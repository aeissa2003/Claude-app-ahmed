import Foundation
import FirebaseFirestore

final class FirebaseFeedRepository: FeedRepositoryProtocol, @unchecked Sendable {
    private let db = Firestore.firestore()

    private var posts: CollectionReference { db.collection("feedPosts") }

    // MARK: - Feed query

    func listFriendsFeedStream(friendUids: [String]) -> AsyncThrowingStream<[FeedPost], Error> {
        AsyncThrowingStream { continuation in
            guard !friendUids.isEmpty else {
                continuation.yield([])
                continuation.finish()
                return
            }

            // Firestore `in` queries accept up to 30 values per query. Chunk friend
            // uids into batches and merge results client-side.
            let chunks = friendUids.chunked(into: 30)
            var listeners: [ListenerRegistration] = []
            var lastResults: [[FeedPost]] = Array(repeating: [], count: chunks.count)

            for (idx, chunk) in chunks.enumerated() {
                let listener = posts
                    .whereField("authorUid", in: chunk)
                    .order(by: "createdAt", descending: true)
                    .limit(to: 100)
                    .addSnapshotListener { snapshot, error in
                        if let error {
                            continuation.finish(throwing: error)
                            return
                        }
                        guard let snapshot else { return }
                        do {
                            let page = try snapshot.documents.map { try $0.data(as: FeedPost.self) }
                            lastResults[idx] = page
                            let merged = lastResults.flatMap { $0 }
                                .sorted { $0.createdAt > $1.createdAt }
                            continuation.yield(merged)
                        } catch {
                            continuation.finish(throwing: error)
                        }
                    }
                listeners.append(listener)
            }

            continuation.onTermination = { _ in
                listeners.forEach { $0.remove() }
            }
        }
    }

    // MARK: - Posts

    func sharePost(author: UserProfile, recipe: Recipe, caption: String?) async throws -> FeedPost {
        let now = Date()
        let post = FeedPost(
            id: UUID().uuidString,
            authorUid: author.id,
            authorHandle: author.handle,
            authorDisplayName: author.displayName,
            authorPhotoURL: author.photoURL,
            recipe: recipe,
            caption: caption?.trimmingCharacters(in: .whitespacesAndNewlines),
            likeCount: 0,
            commentCount: 0,
            createdAt: now
        )
        try posts.document(post.id).setData(from: post)
        return post
    }

    func deletePost(postId: String) async throws {
        try await posts.document(postId).delete()
    }

    // MARK: - Likes

    func toggleLike(postId: String, likerUid: String) async throws -> Bool {
        let likeRef = posts.document(postId).collection("likes").document(likerUid)
        let postRef = posts.document(postId)
        let existing = try await likeRef.getDocument()
        if existing.exists {
            _ = try await db.runTransaction { txn, _ in
                txn.deleteDocument(likeRef)
                txn.updateData(["likeCount": FieldValue.increment(Int64(-1))], forDocument: postRef)
                return nil
            }
            return false
        } else {
            _ = try await db.runTransaction { txn, _ in
                let like = FeedLike(id: likerUid, createdAt: Date())
                do {
                    try txn.setData(from: like, forDocument: likeRef)
                } catch {
                    return nil
                }
                txn.updateData(["likeCount": FieldValue.increment(Int64(1))], forDocument: postRef)
                return nil
            }
            return true
        }
    }

    func hasLiked(postId: String, likerUid: String) async throws -> Bool {
        let doc = try await posts.document(postId).collection("likes").document(likerUid).getDocument()
        return doc.exists
    }

    // MARK: - Comments

    func listCommentsStream(postId: String) -> AsyncThrowingStream<[FeedComment], Error> {
        AsyncThrowingStream { continuation in
            let listener = posts.document(postId).collection("comments")
                .order(by: "createdAt")
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: error)
                        return
                    }
                    guard let snapshot else { return }
                    do {
                        let items = try snapshot.documents.map { try $0.data(as: FeedComment.self) }
                        continuation.yield(items)
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
            continuation.onTermination = { _ in listener.remove() }
        }
    }

    func addComment(postId: String, author: UserProfile, text: String) async throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let comment = FeedComment(
            id: UUID().uuidString,
            authorUid: author.id,
            authorHandle: author.handle,
            authorDisplayName: author.displayName,
            authorPhotoURL: author.photoURL,
            text: trimmed,
            createdAt: Date()
        )
        let postRef = posts.document(postId)
        let commentRef = postRef.collection("comments").document(comment.id)
        _ = try await db.runTransaction { txn, _ in
            do {
                try txn.setData(from: comment, forDocument: commentRef)
            } catch {
                return nil
            }
            txn.updateData(["commentCount": FieldValue.increment(Int64(1))], forDocument: postRef)
            return nil
        }
    }

    func deleteComment(postId: String, commentId: String) async throws {
        let postRef = posts.document(postId)
        let commentRef = postRef.collection("comments").document(commentId)
        _ = try await db.runTransaction { txn, _ in
            txn.deleteDocument(commentRef)
            txn.updateData(["commentCount": FieldValue.increment(Int64(-1))], forDocument: postRef)
            return nil
        }
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
