import FirebaseAuth
import FirebaseCore
import Foundation
import GoogleSignIn
import UIKit

enum GoogleSignInHelper {
    static func signIn() async throws -> User {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.unknown("Missing Firebase clientID. Ensure GoogleService-Info.plist is bundled.")
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let rootVC = await topMostViewController() else {
            throw AuthError.unknown("No root view controller available for Google Sign-In.")
        }

        let gidResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
        guard let idToken = gidResult.user.idToken?.tokenString else {
            throw AuthError.unknown("Google sign-in returned no ID token.")
        }
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: gidResult.user.accessToken.tokenString
        )
        let firebaseResult = try await Auth.auth().signIn(with: credential)
        return firebaseResult.user
    }

    @MainActor
    private static func topMostViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })
        var top = scene?.keyWindow?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}
