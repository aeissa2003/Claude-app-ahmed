import Foundation
import FirebaseFirestore

final class FirebaseWorkoutRepository: WorkoutRepositoryProtocol, @unchecked Sendable {
    private let db = Firestore.firestore()

    private func collection(_ uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("workouts")
    }

    func list(ownerUid: String) async throws -> [Workout] {
        let snap = try await collection(ownerUid)
            .order(by: "startedAt", descending: true)
            .getDocuments()
        return try snap.documents.map { try $0.data(as: Workout.self) }
    }

    func listStream(ownerUid: String) -> AsyncThrowingStream<[Workout], Error> {
        AsyncThrowingStream { continuation in
            let listener = collection(ownerUid)
                .order(by: "startedAt", descending: true)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: error)
                        return
                    }
                    guard let snapshot else { return }
                    do {
                        let workouts = try snapshot.documents.map { try $0.data(as: Workout.self) }
                        continuation.yield(workouts)
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
            continuation.onTermination = { _ in listener.remove() }
        }
    }

    func get(ownerUid: String, id: String) async throws -> Workout? {
        let doc = try await collection(ownerUid).document(id).getDocument()
        guard doc.exists else { return nil }
        return try doc.data(as: Workout.self)
    }

    func save(_ workout: Workout) async throws {
        try collection(workout.ownerUid).document(workout.id).setData(from: workout, merge: true)
    }

    func delete(ownerUid: String, id: String) async throws {
        try await collection(ownerUid).document(id).delete()
    }
}
