import AuthenticationServices
import CryptoKit
import FirebaseAuth
import Foundation
import UIKit

/// Drives Sign in with Apple, converts the Apple credential into a Firebase credential,
/// and completes the Firebase auth handoff. Intended for one-shot use per sign-in attempt.
final class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var currentNonce: String?
    private var continuation: CheckedContinuation<AppleSignInResult, Error>?

    struct AppleSignInResult {
        let firebaseUser: User
        let fullName: PersonNameComponents?
    }

    func start() async throws -> AppleSignInResult {
        try await withCheckedThrowingContinuation { cont in
            self.continuation = cont
            let nonce = Self.randomNonce()
            currentNonce = nonce
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = Self.sha256(nonce)

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    // MARK: - ASAuthorizationControllerDelegate

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let nonce = currentNonce,
            let tokenData = credential.identityToken,
            let tokenString = String(data: tokenData, encoding: .utf8)
        else {
            continuation?.resume(throwing: AuthError.unknown("Malformed Apple credential"))
            continuation = nil
            return
        }

        let firebaseCred = OAuthProvider.appleCredential(
            withIDToken: tokenString,
            rawNonce: nonce,
            fullName: credential.fullName
        )

        let cont = continuation
        continuation = nil
        let fullName = credential.fullName
        Task {
            do {
                let result = try await Auth.auth().signIn(with: firebaseCred)
                cont?.resume(returning: AppleSignInResult(firebaseUser: result.user, fullName: fullName))
            } catch {
                cont?.resume(throwing: error)
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let cont = continuation
        continuation = nil
        if let asError = error as? ASAuthorizationError, asError.code == .canceled {
            cont?.resume(throwing: AuthError.cancelled)
        } else {
            cont?.resume(throwing: error)
        }
    }

    // MARK: - Presentation

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first ?? ASPresentationAnchor()
    }

    // MARK: - Nonce helpers

    private static func randomNonce(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        return String(bytes.map { charset[Int($0) % charset.count] })
    }

    private static func sha256(_ input: String) -> String {
        let hashed = SHA256.hash(data: Data(input.utf8))
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}
