import SwiftUI

/// 5-tab shell with mono uppercase labels and an indigo dot under the active tab,
/// per the athletic-editorial redesign. The previous system `TabView` is replaced
/// with a custom bar so we can control typography and the active-dot affordance.
struct MainTabView: View {
    @Environment(AppEnvironment.self) private var env

    enum Tab: Hashable {
        case today, recipes, train, feed, me
    }

    @State private var selection: Tab = .today
    @State private var unreadCount = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.Colors.bg.ignoresSafeArea()

            Group {
                switch selection {
                case .today:   DashboardView()
                case .recipes: RecipesListView()
                case .train:   WorkoutsListView()
                case .feed:    FeedView()
                case .me:      SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            PCTabBar(selection: $selection, unreadFeed: unreadCount)
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

// MARK: - Custom tab bar

struct PCTabBar: View {
    @Binding var selection: MainTabView.Tab
    /// Small red dot rendered next to the Feed icon when there are unread notifications.
    var unreadFeed: Int = 0

    var body: some View {
        HStack(spacing: 0) {
            tab(.today,   label: "Today",   systemName: "house")
            tab(.recipes, label: "Recipes", systemName: "fork.knife")
            tab(.train,   label: "Train",   systemName: "dumbbell")
            tab(.feed,    label: "Feed",    systemName: "person.2", badge: unreadFeed)
            tab(.me,      label: "Me",      systemName: "sun.max")
        }
        .padding(.top, 12)
        .padding(.bottom, safeBottom())
        .padding(.horizontal, 8)
        .background(
            Theme.Colors.paper.opacity(0.92)
                .background(.ultraThinMaterial)
                .overlay(
                    Divider()
                        .overlay(Theme.Colors.line),
                    alignment: .top
                )
        )
    }

    private func tab(_ value: MainTabView.Tab,
                     label: String,
                     systemName: String,
                     badge: Int = 0) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) { selection = value }
        } label: {
            let active = selection == value
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: active ? "\(systemName).fill" : systemName)
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(active ? Theme.Colors.ink : Theme.Colors.ink3)
                        .frame(width: 28, height: 24)
                    if badge > 0 {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                            .offset(x: 4, y: -2)
                    }
                }
                Text(label.uppercased())
                    .font(Theme.Fonts.mono(9))
                    .tracking(0.9)
                    .foregroundStyle(active ? Theme.Colors.ink : Theme.Colors.ink3)
                Circle()
                    .fill(active ? Theme.Colors.indigo : Color.clear)
                    .frame(width: 4, height: 4)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func safeBottom() -> CGFloat {
        // Fallback: the background material + ZStack already respects the home
        // indicator, but give the labels a little padding above it.
        8
    }
}
