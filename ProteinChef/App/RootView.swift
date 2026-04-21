import SwiftUI

struct RootView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var authState: AuthState = .loading

    var body: some View {
        Group {
            switch authState {
            case .loading:
                ProgressView()
            case .signedOut:
                SignInPlaceholderView()
            case .needsOnboarding:
                OnboardingPlaceholderView()
            case .signedIn:
                MainTabView()
            }
        }
        .task {
            for await state in env.auth.authStateStream() {
                authState = state
            }
        }
    }
}

enum AuthState: Equatable {
    case loading
    case signedOut
    case needsOnboarding(uid: String)
    case signedIn(uid: String)
}
