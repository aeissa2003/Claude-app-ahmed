import SwiftUI

struct SignInView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel = SignInViewModel()
    @State private var showEmailSheet = false

    var body: some View {
        VStack(spacing: Theme.Spacing.l) {
            Spacer()
            VStack(spacing: Theme.Spacing.s) {
                Image(systemName: "fork.knife.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)
                    .foregroundStyle(Theme.Colors.protein)
                Text("ProteinChef")
                    .font(.largeTitle.bold())
                Text("Cook, track, train. High-protein focused.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: Theme.Spacing.m) {
                Button(action: signInWithApple) {
                    HStack {
                        Image(systemName: "applelogo")
                        Text("Continue with Apple").fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .foregroundStyle(.white)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Sign in with Apple")

                Button(action: signInWithGoogle) {
                    HStack {
                        Image(systemName: "g.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                        Text("Continue with Google").fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(.black)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.m)
                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                )

                Button {
                    showEmailSheet = true
                } label: {
                    Text("Continue with email")
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.bordered)
            }

            if let errorText = viewModel.errorText {
                Text(errorText)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Text("By continuing you agree to the (tbd) Terms and Privacy Policy.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.l)
        .sheet(isPresented: $showEmailSheet) {
            EmailAuthView()
                .environment(env)
        }
        .overlay {
            if viewModel.isBusy { ProgressView().controlSize(.large) }
        }
    }

    private func signInWithApple() {
        Task { await viewModel.signInWithApple(auth: env.auth) }
    }

    private func signInWithGoogle() {
        Task { await viewModel.signInWithGoogle(auth: env.auth) }
    }
}

@Observable
final class SignInViewModel {
    var isBusy = false
    var errorText: String?

    @MainActor
    func signInWithApple(auth: AuthServiceProtocol) async {
        await perform { _ = try await auth.signInWithApple() }
    }

    @MainActor
    func signInWithGoogle(auth: AuthServiceProtocol) async {
        await perform { _ = try await auth.signInWithGoogle() }
    }

    @MainActor
    private func perform(_ op: @escaping () async throws -> Void) async {
        isBusy = true
        errorText = nil
        defer { isBusy = false }
        do {
            try await op()
        } catch AuthError.cancelled {
            // no-op
        } catch {
            errorText = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
