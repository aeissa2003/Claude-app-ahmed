import Foundation

protocol WorkoutTemplateRepositoryProtocol: Sendable {
    func list(ownerUid: String) async throws -> [WorkoutTemplate]
    func listStream(ownerUid: String) -> AsyncThrowingStream<[WorkoutTemplate], Error>
    func save(_ template: WorkoutTemplate) async throws
    func delete(ownerUid: String, id: String) async throws
}
