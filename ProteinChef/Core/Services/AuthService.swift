import Foundation

protocol AuthServiceProtocol: Sendable {
    var currentUid: String? { get }
    func authStateStream() -> AsyncStream<AuthState>
    func signInWithApple() async throws
    func signInWithGoogle() async throws
    func signUpWithEmail(email: String, password: String, displayName: String) async throws
    func signInWithEmail(email: String, password: String) async throws
    func sendPasswordReset(email: String) async throws
    func signOut() throws
}

enum AuthError: Error, LocalizedError {
    case notImplemented
    case invalidCredentials
    case cancelled
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notImplemented: "This sign-in method will land in Phase 2."
        case .invalidCredentials: "Incorrect email or password."
        case .cancelled: "Sign-in cancelled."
        case .unknown(let msg): msg
        }
    }
}
