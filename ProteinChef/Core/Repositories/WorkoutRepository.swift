import Foundation

protocol WorkoutRepositoryProtocol: Sendable {
    func list(ownerUid: String) async throws -> [Workout]
    func listStream(ownerUid: String) -> AsyncThrowingStream<[Workout], Error>
    func get(ownerUid: String, id: String) async throws -> Workout?
    func save(_ workout: Workout) async throws
    func delete(ownerUid: String, id: String) async throws
}
