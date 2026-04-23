import Foundation
import FirebaseAuth

final class FirebaseAuthService: AuthServiceProtocol, @unchecked Sendable {
    var currentUid: String? { Auth.auth().currentUser?.uid }
    var currentEmail: String? { Auth.auth().currentUser?.email }
    var currentDisplayName: String? { Auth.auth().currentUser?.displayName }
    var currentPhotoURL: URL? { Auth.auth().currentUser?.photoURL }

    // Held for the duration of an Apple sign-in attempt.
    private var appleCoordinator: AppleSignInCoordinator?

    func authStateStream() -> AsyncStream<AuthState> {
        AsyncStream { continuation in
            let handle = Auth.auth().addStateDidChangeListener { _, user in
                if let uid = user?.uid {
                    continuation.yield(.signedIn(uid: uid))
                } else {
                    continuation.yield(.signedOut)
                }
            }
            continuation.onTermination = { _ in
                Auth.auth().removeStateDidChangeListener(handle)
            }
        }
    }

    func signInWithApple() async throws -> AuthOutcome {
        let coord = AppleSignInCoordinator()
        appleCoordinator = coord
        defer { appleCoordinator = nil }

        let result = try await coord.start()
        let user = result.firebaseUser
        let formatter = PersonNameComponentsFormatter()
        let appleName = result.fullName.map { formatter.string(from: $0) }?.nilIfEmpty
        return AuthOutcome(
            uid: user.uid,
            email: user.email,
            displayName: user.displayName,
            photoURL: user.photoURL,
            suggestedDisplayName: appleName ?? user.displayName
        )
    }

    func signInWithGoogle() async throws -> AuthOutcome {
        let user = try await GoogleSignInHelper.signIn()
        return AuthOutcome(
            uid: user.uid,
            email: user.email,
            displayName: user.displayName,
            photoURL: user.photoURL,
            suggestedDisplayName: user.displayName
        )
    }

    func signInWithEmail(email: String, password: String) async throws -> AuthOutcome {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            return Self.outcome(from: result.user)
        } catch let error as NSError {
            throw Self.mapAuthError(error)
        }
    }

    func signUpWithEmail(email: String, password: String, displayName: String) async throws -> AuthOutcome {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let change = result.user.createProfileChangeRequest()
            change.displayName = displayName
            try await change.commitChanges()
            try await result.user.reload()
            return AuthOutcome(
                uid: result.user.uid,
                email: result.user.email,
                displayName: displayName,
                photoURL: result.user.photoURL,
                suggestedDisplayName: displayName
            )
        } catch let error as NSError {
            throw Self.mapAuthError(error)
        }
    }

    func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    // MARK: -

    private static func outcome(from user: User) -> AuthOutcome {
        AuthOutcome(
            uid: user.uid,
            email: user.email,
            displayName: user.displayName,
            photoURL: user.photoURL,
            suggestedDisplayName: user.displayName
        )
    }

    private static func mapAuthError(_ err: NSError) -> AuthError {
        guard err.domain == AuthErrorDomain,
              let code = AuthErrorCode.Code(rawValue: err.code) else {
            return .unknown(err.localizedDescription)
        }
        return switch code {
        case .userNotFound:      .userNotFound
        case .invalidCredential,
             .wrongPassword,
             .invalidEmail:      .invalidCredentials
        case .weakPassword:      .weakPassword
        case .emailAlreadyInUse: .emailInUse
        default:                 .unknown(err.localizedDescription)
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
