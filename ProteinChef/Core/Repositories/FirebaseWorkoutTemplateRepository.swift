import Foundation
import FirebaseFirestore

final class FirebaseWorkoutTemplateRepository: WorkoutTemplateRepositoryProtocol, @unchecked Sendable {
    private let db = Firestore.firestore()

    private func collection(_ uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("workoutTemplates")
    }

    func list(ownerUid: String) async throws -> [WorkoutTemplate] {
        let snap = try await collection(ownerUid).order(by: "updatedAt", descending: true).getDocuments()
        return try snap.documents.map { try $0.data(as: WorkoutTemplate.self) }
    }

    func listStream(ownerUid: String) -> AsyncThrowingStream<[WorkoutTemplate], Error> {
        AsyncThrowingStream { continuation in
            let listener = collection(ownerUid)
                .order(by: "updatedAt", descending: true)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: error)
                        return
                    }
                    guard let snapshot else { return }
                    do {
                        let items = try snapshot.documents.map { try $0.data(as: WorkoutTemplate.self) }
                        continuation.yield(items)
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
            continuation.onTermination = { _ in listener.remove() }
        }
    }

    func save(_ template: WorkoutTemplate) async throws {
        try collection(template.ownerUid).document(template.id).setData(from: template, merge: true)
    }

    func delete(ownerUid: String, id: String) async throws {
        try await collection(ownerUid).document(id).delete()
    }
}
