import Foundation
import FirebaseFirestore

final class FirebaseRecipeRepository: RecipeRepositoryProtocol, @unchecked Sendable {
    private let db = Firestore.firestore()

    private func collection(_ uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("recipes")
    }

    func list(ownerUid: String) async throws -> [Recipe] {
        let snapshot = try await collection(ownerUid)
            .order(by: "updatedAt", descending: true)
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: Recipe.self) }
    }

    func listStream(ownerUid: String) -> AsyncThrowingStream<[Recipe], Error> {
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
                        let recipes = try snapshot.documents.map { try $0.data(as: Recipe.self) }
                        continuation.yield(recipes)
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
            continuation.onTermination = { _ in listener.remove() }
        }
    }

    func get(ownerUid: String, recipeId: String) async throws -> Recipe? {
        let doc = try await collection(ownerUid).document(recipeId).getDocument()
        guard doc.exists else { return nil }
        return try doc.data(as: Recipe.self)
    }

    func save(_ recipe: Recipe) async throws {
        try collection(recipe.ownerUid).document(recipe.id).setData(from: recipe, merge: true)
    }

    func delete(ownerUid: String, recipeId: String) async throws {
        try await collection(ownerUid).document(recipeId).delete()
    }
}
