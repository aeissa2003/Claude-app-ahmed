import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct ProteinChefApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var environment: AppEnvironment

    init() {
        // Must run before AppEnvironment.live() since repositories call Firestore.firestore()
        // eagerly. AppDelegate's didFinishLaunching fires later than @State init.
        FirebaseApp.configure()
        let env = AppEnvironment.live()
        _environment = State(initialValue: env)

        // Forward FCM tokens from the UIKit delegate to the push service, which
        // persists them onto the currently-signed-in user's profile.
        PushBridge.onToken = { token in
            guard let uid = env.auth.currentUid else { return }
            Task { await env.push.updateFCMToken(token, forUid: uid) }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
