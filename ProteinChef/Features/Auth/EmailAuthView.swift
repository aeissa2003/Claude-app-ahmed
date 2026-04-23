import SwiftUI

/// Unified email flow: user enters email + password.
/// On submit, try sign-in. If user-not-found, surface a "Create account" step asking for a display name.
struct EmailAuthView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    enum Step { case credentials, createAccount, reset }

    @State private var step: Step = .credentials
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var errorText: String?
    @State private var isBusy = false

    var body: some View {
        NavigationStack {
            Form {
                switch step {
                case .credentials: credentialsSection
                case .createAccount: createAccountSection
                case .reset: resetSection
                }

                if let errorText {
                    Section { Text(errorText).foregroundStyle(.red) }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(primaryButtonTitle) { Task { await primaryAction() } }
                        .disabled(!primaryEnabled || isBusy)
                }
            }
            .overlay { if isBusy { ProgressView().controlSize(.large) } }
        }
    }

    private var title: String {
        switch step {
        case .credentials: "Continue with email"
        case .createAccount: "Create account"
        case .reset: "Reset password"
        }
    }

    private var primaryButtonTitle: String {
        switch step {
        case .credentials: "Continue"
        case .createAccount: "Sign up"
        case .reset: "Send email"
        }
    }

    private var primaryEnabled: Bool {
        switch step {
        case .credentials:
            email.contains("@") && password.count >= 6
        case .createAccount:
            email.contains("@") && password.count >= 6 && !displayName.trimmingCharacters(in: .whitespaces).isEmpty
        case .reset:
            email.contains("@")
        }
    }

    @ViewBuilder
    private var credentialsSection: some View {
        Section {
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
            SecureField("Password", text: $password)
                .textContentType(.password)
        } footer: {
            HStack {
                Button("Create account") {
                    step = .createAccount
                    errorText = nil
                }
                Spacer()
                Button("Forgot password?") { step = .reset; errorText = nil }
            }
        }
    }

    @ViewBuilder
    private var createAccountSection: some View {
        Section {
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
            SecureField("Password (min 6 chars)", text: $password)
                .textContentType(.newPassword)
            TextField("Display name", text: $displayName)
                .textContentType(.name)
        } footer: {
            Button("I already have an account") {
                step = .credentials
                errorText = nil
            }
        }
    }

    @ViewBuilder
    private var resetSection: some View {
        Section {
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
        } footer: {
            Button("Back to sign in") { step = .credentials; errorText = nil }
        }
    }

    @MainActor
    private func primaryAction() async {
        isBusy = true
        errorText = nil
        defer { isBusy = false }

        do {
            switch step {
            case .credentials:
                do {
                    _ = try await env.auth.signInWithEmail(email: email, password: password)
                    dismiss()
                } catch AuthError.userNotFound {
                    step = .createAccount
                }
            case .createAccount:
                _ = try await env.auth.signUpWithEmail(
                    email: email,
                    password: password,
                    displayName: displayName.trimmingCharacters(in: .whitespaces)
                )
                dismiss()
            case .reset:
                try await env.auth.sendPasswordReset(email: email)
                errorText = "Reset email sent. Check your inbox."
                step = .credentials
            }
        } catch {
            errorText = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
