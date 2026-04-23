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
        _environment = State(initialValue: AppEnvironment.live())
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
