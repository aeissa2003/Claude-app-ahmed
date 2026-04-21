import Foundation
import FirebaseStorage

final class FirebaseStorageService: StorageServiceProtocol, @unchecked Sendable {
    private let storage = Storage.storage()

    func uploadJPEG(_ data: Data, to path: String) async throws -> URL {
        let ref = storage.reference(withPath: path)
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        _ = try await ref.putDataAsync(data, metadata: meta)
        return try await ref.downloadURL()
    }

    func delete(path: String) async throws {
        try await storage.reference(withPath: path).delete()
    }
}
