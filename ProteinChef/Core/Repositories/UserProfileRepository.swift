import Foundation

protocol UserProfileRepositoryProtocol: Sendable {
    func fetch(uid: String) async throws -> UserProfile?
    func save(_ profile: UserProfile) async throws
    func isHandleAvailable(_ handle: String) async throws -> Bool
    /// Atomically reserves a handle for the given uid. Throws if already taken.
    func reserveHandle(_ handle: String, uid: String) async throws
    /// Releases the current handle and reserves a new one in a single transaction.
    func changeHandle(from oldHandle: String?, to newHandle: String, uid: String) async throws
}

enum HandleError: LocalizedError {
    case invalidFormat
    case alreadyTaken

    var errorDescription: String? {
        switch self {
        case .invalidFormat: "Handle must be 3–20 chars, letters/numbers/underscore, start with a letter."
        case .alreadyTaken: "That handle is already taken."
        }
    }
}

enum HandleValidator {
    /// Lowercase, 3–20 chars, starts with a letter, then letters/digits/underscore.
    static let pattern = #"^[a-z][a-z0-9_]{2,19}$"#

    static func normalize(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespaces).lowercased()
    }

    static func isValid(_ handle: String) -> Bool {
        let normalized = normalize(handle)
        return normalized.range(of: pattern, options: .regularExpression) != nil
    }
}
