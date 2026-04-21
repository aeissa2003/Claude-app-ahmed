import Foundation
import FirebaseAuth

/// Phase 1 stub: wires Firebase's auth state listener so the app can route between signed-in
/// and signed-out. Real Apple / Google / email flows land in Phase 2.
final class FirebaseAuthService: AuthServiceProtocol, @unchecked Sendable {
    var currentUid: String? { Auth.auth().currentUser?.uid }

    func authStateStream() -> AsyncStream<AuthState> {
        AsyncStream { continuation in
            let handle = Auth.auth().addStateDidChangeListener { _, user in
                if user == nil {
                    continuation.yield(.signedOut)
                } else if let uid = user?.uid {
                    // Phase 2 will look up the user's profile and yield .needsOnboarding vs .signedIn
                    // based on whether onboardingCompletedAt is set. For now, route to onboarding.
                    continuation.yield(.needsOnboarding(uid: uid))
                }
            }
            continuation.onTermination = { _ in
                Auth.auth().removeStateDidChangeListener(handle)
            }
        }
    }

    func signInWithApple() async throws { throw AuthError.notImplemented }
    func signInWithGoogle() async throws { throw AuthError.notImplemented }
    func signUpWithEmail(email: String, password: String, displayName: String) async throws {
        throw AuthError.notImplemented
    }
    func signInWithEmail(email: String, password: String) async throws { throw AuthError.notImplemented }
    func sendPasswordReset(email: String) async throws { throw AuthError.notImplemented }
    func signOut() throws { try Auth.auth().signOut() }
}
