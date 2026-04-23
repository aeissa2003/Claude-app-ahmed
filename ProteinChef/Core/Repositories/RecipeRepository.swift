import Foundation

protocol RecipeRepositoryProtocol: Sendable {
    func list(ownerUid: String) async throws -> [Recipe]
    func listStream(ownerUid: String) -> AsyncThrowingStream<[Recipe], Error>
    func get(ownerUid: String, recipeId: String) async throws -> Recipe?
    func save(_ recipe: Recipe) async throws
    func delete(ownerUid: String, recipeId: String) async throws
}
