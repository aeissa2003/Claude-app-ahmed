import Foundation

protocol FirestoreServiceProtocol: Sendable {
    // Phase 2+ will add concrete read/write methods as each feature lands.
    // Keeping this minimal in Phase 1 so we don't freeze the interface prematurely.
    func ping() async throws
}
