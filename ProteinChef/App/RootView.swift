import SwiftUI

enum AuthState: Equatable {
    case loading
    case signedOut
    case signedIn(uid: String)
}

struct RootView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var authState: AuthState = .loading
    @State private var profile: UserProfile?
    @State private var profileLoading = false

    var body: some View {
        Group {
            switch authState {
            case .loading:
                ProgressView()
            case .signedOut:
                SignInView()
            case .signedIn(let uid):
                if profileLoading {
                    ProgressView().task { await loadProfile(uid: uid) }
                } else if let profile, profile.isOnboarded {
                    MainTabView().environment(\.userProfile, profile)
                } else {
                    OnboardingFlow(
                        uid: uid,
                        seedDisplayName: env.auth.currentDisplayName ?? "",
                        seedEmail: env.auth.currentEmail,
                        onComplete: { completed in
                            profile = completed
                        }
                    )
                }
            }
        }
        .task(id: authStateKey(authState)) {
            if case .signedIn(let uid) = authState {
                await loadProfile(uid: uid)
            } else {
                profile = nil
            }
        }
        .task {
            for await state in env.auth.authStateStream() {
                authState = state
            }
        }
    }

    private func loadProfile(uid: String) async {
        profileLoading = true
        defer { profileLoading = false }
        do {
            profile = try await env.userProfiles.fetch(uid: uid)
        } catch {
            profile = nil
        }
    }

    private func authStateKey(_ s: AuthState) -> String {
        switch s {
        case .loading:             "loading"
        case .signedOut:           "signedOut"
        case .signedIn(let uid):   "signedIn:\(uid)"
        }
    }
}

private struct UserProfileKey: EnvironmentKey {
    static let defaultValue: UserProfile? = nil
}

extension EnvironmentValues {
    var userProfile: UserProfile? {
        get { self[UserProfileKey.self] }
        set { self[UserProfileKey.self] = newValue }
    }
}
