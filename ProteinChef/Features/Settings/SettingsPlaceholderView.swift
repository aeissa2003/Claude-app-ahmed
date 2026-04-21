import SwiftUI

struct SettingsPlaceholderView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    Button("Sign out", role: .destructive) {
                        try? env.auth.signOut()
                    }
                }
                Section {
                    Text("Units toggle, notification prefs, protein goal edit, and account deletion arrive in later phases.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
