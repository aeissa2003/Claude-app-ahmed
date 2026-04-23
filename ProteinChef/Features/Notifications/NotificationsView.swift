import SwiftUI

struct NotificationsView: View {
    @Environment(AppEnvironment.self) private var env

    @State private var items: [AppNotification] = []
    @State private var loadError: String?

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView {
                        Label("No notifications yet", systemImage: "bell.slash")
                    } description: {
                        Text("Friend activity and recipe shares will show up here.")
                    }
                } else {
                    List {
                        ForEach(items) { item in
                            row(item)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        Task { await delete(item) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Inbox")
            .toolbar {
                if items.contains(where: { !$0.read }) {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Mark all read") {
                            Task { await markAllRead() }
                        }
                    }
                }
            }
            .task(id: env.auth.currentUid ?? "") { await subscribe() }
            .alert("Couldn’t load", isPresented: .constant(loadError != nil)) {
                Button("OK") { loadError = nil }
            } message: { Text(loadError ?? "") }
        }
    }

    private func row(_ item: AppNotification) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.s) {
            avatar(item)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title).font(.subheadline.bold())
                Text(item.body).font(.footnote).foregroundStyle(.secondary)
                Text(relative(item.createdAt))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            if !item.read {
                Circle()
                    .fill(Theme.Colors.protein)
                    .frame(width: 8, height: 8)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { Task { await markRead(item) } }
    }

    @ViewBuilder
    private func avatar(_ item: AppNotification) -> some View {
        if let url = item.actorPhotoURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img): img.resizable().scaledToFill()
                default: Color.secondary.opacity(0.1)
                }
            }
            .frame(width: 36, height: 36)
            .clipShape(Circle())
        } else {
            Circle()
                .fill(Color.secondary.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay(Image(systemName: icon(for: item.kind)).foregroundStyle(.secondary))
        }
    }

    private func icon(for kind: AppNotification.Kind) -> String {
        switch kind {
        case .friendRequest: "person.badge.plus"
        case .friendAccepted: "person.2.fill"
        case .newFeedPost: "fork.knife"
        case .feedLike: "heart.fill"
        case .feedComment: "bubble.left.fill"
        }
    }

    private func relative(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: Date())
    }

    private func subscribe() async {
        guard let uid = env.auth.currentUid else {
            items = []
            return
        }
        do {
            for try await list in env.notifications.listStream(uid: uid) {
                items = list
            }
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func markRead(_ item: AppNotification) async {
        guard let uid = env.auth.currentUid, !item.read else { return }
        try? await env.notifications.markRead(uid: uid, notificationId: item.id)
    }

    private func markAllRead() async {
        guard let uid = env.auth.currentUid else { return }
        try? await env.notifications.markAllRead(uid: uid)
    }

    private func delete(_ item: AppNotification) async {
        guard let uid = env.auth.currentUid else { return }
        try? await env.notifications.delete(uid: uid, notificationId: item.id)
    }
}
