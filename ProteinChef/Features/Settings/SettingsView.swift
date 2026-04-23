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
    @State private var recipeCount: Int = 0
    @State private var workoutCount: Int = 0

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Theme.Colors.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    PCAppBar(title: "Me", eyebrow: "Account · settings") {
                        PCIconButton(systemName: "pencil", variant: .paper) {}
                    }
                    ScrollView {
                        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                            if let profile {
                                profileCard(profile)
                            }
                            statsRow
                            targetsCard
                            menuList
                            dangerSection
                        }
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.bottom, 140)
                    }
                }
            }
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
            .task(id: env.auth.currentUid ?? "") { await subscribeStats() }
        }
    }

    // MARK: - Profile card

    private func profileCard(_ p: UserProfile) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Theme.Colors.indigo)
                    .frame(width: 64, height: 64)
                if let url = p.photoURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img): img.resizable().scaledToFill()
                        default: Color.clear
                        }
                    }
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                } else {
                    Text(String(p.displayName.prefix(1)).uppercased())
                        .font(Theme.Fonts.display(28))
                        .foregroundStyle(.white)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(p.displayName)
                    .font(Theme.Fonts.display(24))
                    .tracking(-0.5)
                Text("@\(p.handle)")
                    .font(Theme.Fonts.mono(11))
                    .foregroundStyle(Theme.Colors.ink3)
            }
            Spacer()
        }
        .padding(16)
        .background(Theme.Colors.paper)
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.l).stroke(Theme.Colors.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l))
    }

    // MARK: - Stats row

    private var statsRow: some View {
        HStack(spacing: 10) {
            PCStatTile(value: "\(recipeCount)", label: "Recipes")
            PCStatTile(value: "\(workoutCount)", label: "Workouts")
            PCStatTile(value: streakText, label: "Streak")
        }
    }

    private var streakText: String {
        "—"  // placeholder until a real daily-log streak lands
    }

    // MARK: - Targets card

    private var targetsCard: some View {
        let p = profile
        return VStack(spacing: 14) {
            HStack {
                Text("Daily targets").font(Theme.Fonts.ui(16, weight: .semibold))
                Spacer()
                Button("EDIT") {}
                    .font(Theme.Fonts.mono(10, weight: .semibold))
                    .tracking(1.0)
                    .foregroundStyle(Theme.Colors.indigo)
            }
            targetRow(label: "Protein",    value: "\(Int(p?.proteinGoalG ?? 0))", unit: "g", color: Theme.Colors.protein)
            Divider().overlay(Theme.Colors.line)
            targetRow(label: "Calories",   value: "\(Int(p?.calorieGoalKcal ?? 0))", unit: "kcal", color: Theme.Colors.ink)
            Divider().overlay(Theme.Colors.line)
            targetRow(label: "Bodyweight", value: "\(Int(p?.weightKg ?? 0))", unit: "kg", color: Theme.Colors.ink)
            Divider().overlay(Theme.Colors.line)
            HStack {
                Text("Goal").font(Theme.Fonts.ui(14))
                Spacer()
                Text(goalLabel).font(Theme.Fonts.display(16))
            }
        }
        .padding(18)
        .background(Theme.Colors.paper)
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.l).stroke(Theme.Colors.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l))
    }

    private func targetRow(label: String, value: String, unit: String, color: Color) -> some View {
        HStack {
            Text(label).font(Theme.Fonts.ui(14))
            Spacer()
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value).font(Theme.Fonts.display(18)).foregroundStyle(color)
                Text(unit).font(Theme.Fonts.ui(11)).foregroundStyle(Theme.Colors.ink3)
            }
        }
    }

    private var goalLabel: String {
        switch profile?.goal {
        case .cut: "Cut"
        case .maintain: "Maintain"
        case .bulk: "Build"
        default: "—"
        }
    }

    // MARK: - Menu list

    private var menuList: some View {
        VStack(spacing: 0) {
            menuRow(icon: "bell", label: "Notifications",
                    trailing: pushAuthorized ? "On" : "Off",
                    action: openSystemSettings)
            Divider().overlay(Theme.Colors.line)
            menuRow(icon: "ruler", label: "Units",
                    trailing: profile?.unitsPref == .imperial ? "Imperial" : "Metric",
                    action: {})
            Divider().overlay(Theme.Colors.line)
            menuRow(icon: "person.2", label: "Friends",
                    trailing: "",
                    action: {})
            Divider().overlay(Theme.Colors.line)
            menuRow(icon: "square.and.arrow.up", label: "Share ProteinChef",
                    trailing: "",
                    action: {})
        }
        .background(Theme.Colors.paper)
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.l).stroke(Theme.Colors.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l))
    }

    private func menuRow(icon: String,
                         label: String,
                         trailing: String,
                         action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.Colors.ink3)
                    .frame(width: 28, height: 28)
                    .background(Theme.Colors.ink.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Text(label)
                    .font(Theme.Fonts.ui(14, weight: .medium))
                    .foregroundStyle(Theme.Colors.ink)
                Spacer()
                if !trailing.isEmpty {
                    Text(trailing)
                        .font(Theme.Fonts.mono(11))
                        .foregroundStyle(Theme.Colors.ink3)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Colors.ink4)
            }
            .padding(14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Danger

    private var dangerSection: some View {
        VStack(spacing: 10) {
            Button(role: .destructive) {
                try? env.auth.signOut()
            } label: {
                Text("Sign out")
                    .font(Theme.Fonts.ui(15, weight: .semibold))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            Button(role: .destructive) {
                showingDeleteConfirm = true
            } label: {
                Text("Delete account")
                    .font(Theme.Fonts.mono(11, weight: .semibold))
                    .tracking(1.0)
                    .foregroundStyle(Theme.Colors.ink3)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
        }
        .padding(.top, Theme.Spacing.s)
    }

    // MARK: - Actions

    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func deleteAccount() async {
        guard let profile else { return }
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await env.accountDeletion.deleteAccount(uid: profile.id, handle: profile.handle)
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

    private func subscribeStats() async {
        guard let uid = env.auth.currentUid else { return }
        async let a: () = subscribeRecipeCount(uid: uid)
        async let b: () = subscribeWorkoutCount(uid: uid)
        _ = await (a, b)
    }

    private func subscribeRecipeCount(uid: String) async {
        do {
            for try await list in env.recipes.listStream(ownerUid: uid) {
                recipeCount = list.count
            }
        } catch {}
    }

    private func subscribeWorkoutCount(uid: String) async {
        do {
            for try await list in env.workouts.listStream(ownerUid: uid) {
                workoutCount = list.count
            }
        } catch {}
    }
}
