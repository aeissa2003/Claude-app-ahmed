import Foundation
import FirebaseFirestore

final class FirebaseCustomExerciseRepository: CustomExerciseRepositoryProtocol, @unchecked Sendable {
    private let db = Firestore.firestore()

    private func collection(_ uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("customExercises")
    }

    func list(ownerUid: String) async throws -> [CustomExercise] {
        let snap = try await collection(ownerUid).order(by: "name").getDocuments()
        return try snap.documents.map { try $0.data(as: CustomExercise.self) }
    }

    func save(ownerUid: String, _ exercise: CustomExercise) async throws {
        try collection(ownerUid).document(exercise.id).setData(from: exercise, merge: true)
    }

    func delete(ownerUid: String, id: String) async throws {
        try await collection(ownerUid).document(id).delete()
    }
}
