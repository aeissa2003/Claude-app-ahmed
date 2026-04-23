import SwiftUI
import UIKit
import UserNotifications

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.userProfile) private var profile

    @State private var showingDeleteConfirm = false
    @State private var isDeleting = false
    @State private var errorText: String?
    @State private var pushAuthorized = false

    var body: some View {
        NavigationStack {
            Form {
                if let profile {
                    accountSection(profile: profile)
                }
                preferencesSection
                notificationsSection
                aboutSection
                dangerSection
            }
            .navigationTitle("Settings")
            .alert("Delete your account?", isPresented: $showingDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { Task { await deleteAccount() } }
            } message: {
                Text("This permanently removes your recipes, meal logs, workouts, and friendships. This cannot be undone.")
            }
            .alert("Error", isPresented: .constant(errorText != nil)) {
                Button("OK") { errorText = nil }
            } message: { Text(errorText ?? "") }
            .overlay {
                if isDeleting {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView("Deleting…").controlSize(.large)
                }
            }
            .task { await refreshPushStatus() }
        }
    }

    // MARK: - Sections

    private func accountSection(profile: UserProfile) -> some View {
        Section("Account") {
            LabeledContent("Name", value: profile.displayName)
            LabeledContent("Handle", value: "@\(profile.handle)")
            if let email = profile.email {
                LabeledContent("Email", value: email)
            }
        }
    }

    private var preferencesSection: some View {
        Section("Preferences") {
            Text("Units: \(profile?.unitsPref == .imperial ? "Imperial" : "Metric")")
                .foregroundStyle(.secondary)
            Text("Unit switching, goal editing, and dietary preference updates arrive in a future build.")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
    }

    private var notificationsSection: some View {
        Section {
            LabeledContent("Push notifications", value: pushAuthorized ? "Enabled" : "Off")
            if !pushAuthorized {
                Button("Open Settings to enable") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        } header: {
            Text("Notifications")
        } footer: {
            Text("You'll receive pushes for friend requests, likes, comments, and new posts from friends.")
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: Bundle.main.versionDisplay)
            Link("Privacy policy", destination: URL(string: "https://example.com/proteinchef/privacy")!)
            Link("Terms of service", destination: URL(string: "https://example.com/proteinchef/terms")!)
        }
    }

    private var dangerSection: some View {
        Section {
            Button("Sign out", role: .destructive) {
                try? env.auth.signOut()
            }
            Button("Delete account", role: .destructive) {
                showingDeleteConfirm = true
            }
        }
    }

    // MARK: - Actions

    private func deleteAccount() async {
        guard let profile else { return }
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await env.accountDeletion.deleteAccount(uid: profile.id, handle: profile.handle)
            // RootView will auto-redirect to the auth gate once the listener
            // observes the signed-out state.
        } catch AuthError.requiresRecentLogin {
            errorText = "For security, sign out and sign back in, then retry."
            try? env.auth.signOut()
        } catch {
            errorText = error.localizedDescription
        }
    }

    @MainActor
    private func refreshPushStatus() async {
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings().authorizationStatus
        pushAuthorized = (status == .authorized || status == .provisional)
    }
}

private extension Bundle {
    var versionDisplay: String {
        let v = infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(v) (\(b))"
    }
}
