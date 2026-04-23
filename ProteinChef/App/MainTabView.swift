import SwiftUI

struct MainTabView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var unreadCount = 0

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Today", systemImage: "chart.bar.fill") }
            RecipesListView()
                .tabItem { Label("Recipes", systemImage: "fork.knife") }
            WorkoutsListView()
                .tabItem { Label("Workouts", systemImage: "dumbbell.fill") }
            FeedView()
                .tabItem { Label("Friends", systemImage: "person.2.fill") }
            NotificationsView()
                .tabItem { Label("Inbox", systemImage: "bell.fill") }
                .badge(unreadCount)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .task { await requestPushAuthorizationIfNeeded() }
        .task(id: env.auth.currentUid ?? "") { await subscribeUnread() }
    }

    private func requestPushAuthorizationIfNeeded() async {
        let granted = await env.push.requestAuthorization()
        if granted {
            env.push.registerForRemoteNotifications()
        }
    }

    private func subscribeUnread() async {
        guard let uid = env.auth.currentUid else {
            unreadCount = 0
            return
        }
        do {
            for try await count in env.notifications.unreadCountStream(uid: uid) {
                unreadCount = count
            }
        } catch {
            unreadCount = 0
        }
    }
}
