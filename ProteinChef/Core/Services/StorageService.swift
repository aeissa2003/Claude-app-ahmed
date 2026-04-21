import Foundation

protocol StorageServiceProtocol: Sendable {
    func uploadJPEG(_ data: Data, to path: String) async throws -> URL
    func delete(path: String) async throws
}
