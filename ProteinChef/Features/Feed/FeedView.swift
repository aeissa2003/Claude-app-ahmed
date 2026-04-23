import SwiftUI

struct FeedView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.userProfile) private var profile

    @State private var friendUids: [String] = []
    @State private var posts: [FeedPost] = []
    @State private var likedIds: Set<String> = []
    @State private var showingFriends = false
    @State private var loadError: String?

    var body: some View {
        NavigationStack {
            Group {
                if friendUids.isEmpty {
                    emptyState
                } else if posts.isEmpty {
                    ContentUnavailableView {
                        Label("Nothing new yet", systemImage: "sparkles")
                    } description: {
                        Text("When your friends share recipes, you'll see them here.")
                    }
                } else {
                    List {
                        ForEach(posts) { post in
                            NavigationLink(value: post) {
                                FeedPostCard(post: post, liked: likedIds.contains(post.id))
                            }
                            .swipeActions(edge: .trailing) {
                                if post.authorUid == profile?.id {
                                    Button(role: .destructive) {
                                        Task { await deletePost(post) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Feed")
            .navigationDestination(for: FeedPost.self) { post in
                FeedPostDetailView(post: post, initiallyLiked: likedIds.contains(post.id))
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingFriends = true
                    } label: {
                        Image(systemName: "person.2.fill")
                    }
                    .accessibilityLabel("Manage friends")
                }
            }
            .sheet(isPresented: $showingFriends) {
                FriendsView().environment(env)
            }
            .task(id: env.auth.currentUid ?? "") {
                await subscribeFriends()
            }
            .task(id: friendUidsKey) {
                await subscribeFeed()
            }
            .alert("Couldn’t load feed", isPresented: .constant(loadError != nil)) {
                Button("OK") { loadError = nil }
            } message: {
                Text(loadError ?? "")
            }
        }
    }

    private var friendUidsKey: String {
        friendUids.sorted().joined(separator: ",")
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No friends yet", systemImage: "person.2.slash")
        } description: {
            Text("Add friends by their handle to see what they're cooking.")
        } actions: {
            Button("Find friends") { showingFriends = true }
                .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Subscriptions

    private func subscribeFriends() async {
        guard let uid = env.auth.currentUid else { return }
        do {
            for try await list in env.friends.listFriendsStream(uid: uid) {
                friendUids = list.map { $0.id }
            }
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func subscribeFeed() async {
        guard !friendUids.isEmpty else {
            posts = []
            return
        }
        do {
            for try await list in env.feed.listFriendsFeedStream(friendUids: friendUids) {
                posts = list
                await refreshLikedStatus()
            }
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func refreshLikedStatus() async {
        guard let uid = env.auth.currentUid else { return }
        var liked: Set<String> = []
        // Check like status for just the visible posts (up to 30) to avoid heavy fanout.
        for post in posts.prefix(30) {
            if (try? await env.feed.hasLiked(postId: post.id, likerUid: uid)) == true {
                liked.insert(post.id)
            }
        }
        likedIds = liked
    }

    private func deletePost(_ post: FeedPost) async {
        do {
            try await env.feed.deletePost(postId: post.id)
        } catch {
            loadError = error.localizedDescription
        }
    }
}

struct FeedPostCard: View {
    let post: FeedPost
    let liked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack(spacing: Theme.Spacing.s) {
                avatar
                VStack(alignment: .leading, spacing: 0) {
                    Text(post.authorDisplayName).font(.subheadline.bold())
                    Text("@\(post.authorHandle)").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text(relativeTime).font(.caption).foregroundStyle(.tertiary)
            }
            if let caption = post.caption, !caption.isEmpty {
                Text(caption).font(.body)
            }
            recipeCard
            HStack(spacing: Theme.Spacing.m) {
                Label("\(post.likeCount)", systemImage: liked ? "heart.fill" : "heart")
                    .foregroundStyle(liked ? .red : .secondary)
                Label("\(post.commentCount)", systemImage: "bubble.left")
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder private var avatar: some View {
        if let url = post.authorPhotoURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img): img.resizable().scaledToFill()
                default: Color.secondary.opacity(0.1)
                }
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
        } else {
            Circle()
                .fill(Color.secondary.opacity(0.15))
                .frame(width: 32, height: 32)
                .overlay(Image(systemName: "person.fill").foregroundStyle(.secondary))
        }
    }

    private var recipeCard: some View {
        HStack(spacing: Theme.Spacing.m) {
            recipeThumb
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(post.recipe.title).font(.subheadline.bold())
                    if post.recipe.isHighProtein {
                        Text("HP").font(.caption2.bold())
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(Theme.Colors.protein.opacity(0.2))
                            .foregroundStyle(Theme.Colors.protein)
                            .clipShape(Capsule())
                    }
                }
                Text("\(Int(post.recipe.macrosPerServing.proteinG))g P · \(Int(post.recipe.macrosPerServing.kcal)) kcal / serving")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(Theme.Spacing.s)
        .background(Color.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
    }

    @ViewBuilder private var recipeThumb: some View {
        if let url = post.recipe.coverPhotoURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img): img.resizable().scaledToFill()
                default: Color.secondary.opacity(0.1)
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.s))
        } else {
            RoundedRectangle(cornerRadius: Theme.Radius.s)
                .fill(Color.secondary.opacity(0.1))
                .frame(width: 48, height: 48)
                .overlay(Image(systemName: "fork.knife").foregroundStyle(.secondary))
        }
    }

    private var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: post.createdAt, relativeTo: Date())
    }
}
