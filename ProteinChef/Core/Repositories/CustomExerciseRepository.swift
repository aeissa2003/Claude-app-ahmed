import Foundation

protocol CustomExerciseRepositoryProtocol: Sendable {
    func list(ownerUid: String) async throws -> [CustomExercise]
    func save(ownerUid: String, _ exercise: CustomExercise) async throws
    func delete(ownerUid: String, id: String) async throws
}
