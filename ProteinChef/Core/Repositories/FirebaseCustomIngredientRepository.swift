import Foundation
import FirebaseFirestore

final class FirebaseCustomIngredientRepository: CustomIngredientRepositoryProtocol, @unchecked Sendable {
    private let db = Firestore.firestore()

    private func collection(_ uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("customIngredients")
    }

    func list(ownerUid: String) async throws -> [CustomIngredient] {
        let snap = try await collection(ownerUid).order(by: "name").getDocuments()
        return try snap.documents.map { try $0.data(as: CustomIngredient.self) }
    }

    func save(ownerUid: String, _ ingredient: CustomIngredient) async throws {
        try collection(ownerUid).document(ingredient.id).setData(from: ingredient, merge: true)
    }

    func delete(ownerUid: String, id: String) async throws {
        try await collection(ownerUid).document(id).delete()
    }
}
