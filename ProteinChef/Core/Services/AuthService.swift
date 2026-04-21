import Foundation

protocol AuthServiceProtocol: Sendable {
    var currentUid: String? { get }
    var currentEmail: String? { get }
    var currentDisplayName: String? { get }
    var currentPhotoURL: URL? { get }

    func authStateStream() -> AsyncStream<AuthState>

    func signInWithApple() async throws -> AuthOutcome
    func signInWithGoogle() async throws -> AuthOutcome
    func signInWithEmail(email: String, password: String) async throws -> AuthOutcome
    func signUpWithEmail(email: String, password: String, displayName: String) async throws -> AuthOutcome
    func sendPasswordReset(email: String) async throws
    func signOut() throws
}

struct AuthOutcome: Sendable {
    let uid: String
    let email: String?
    let displayName: String?
    let photoURL: URL?
    /// Hint for the caller: Apple / Google may provide a full name component that
    /// the app can use to pre-fill onboarding.
    let suggestedDisplayName: String?
}

enum AuthError: Error, LocalizedError {
    case notImplemented
    case invalidCredentials
    case userNotFound
    case weakPassword
    case emailInUse
    case cancelled
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notImplemented:    "This sign-in method is not available yet."
        case .invalidCredentials:"Incorrect email or password."
        case .userNotFound:      "No account found for that email."
        case .weakPassword:      "Password must be at least 6 characters."
        case .emailInUse:        "An account with that email already exists. Try signing in instead."
        case .cancelled:         "Sign-in cancelled."
        case .unknown(let msg):  msg
        }
    }
}
