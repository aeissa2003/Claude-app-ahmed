import Foundation

protocol CustomIngredientRepositoryProtocol: Sendable {
    func list(ownerUid: String) async throws -> [CustomIngredient]
    func save(ownerUid: String, _ ingredient: CustomIngredient) async throws
    func delete(ownerUid: String, id: String) async throws
}
