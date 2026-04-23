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
            ZStack(alignment: .top) {
                Theme.Colors.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    PCAppBar(title: "Feed",
                             eyebrow: "\(friendUids.count) friends · cooking this week") {
                        HStack(spacing: 8) {
                            PCIconButton(systemName: "person.2", variant: .paper) {
                                showingFriends = true
                            }
                            PCIconButton(systemName: "magnifyingglass", variant: .paper) {}
                        }
                    }
                    content
                }
            }
            .navigationDestination(for: FeedPost.self) { post in
                FeedPostDetailView(post: post, initiallyLiked: likedIds.contains(post.id))
            }
            .sheet(isPresented: $showingFriends) {
                FriendsView().environment(env)
            }
            .task(id: env.auth.currentUid ?? "") { await subscribeFriends() }
            .task(id: friendUidsKey) { await subscribeFeed() }
            .alert("Couldn’t load feed", isPresented: .constant(loadError != nil)) {
                Button("OK") { loadError = nil }
            } message: { Text(loadError ?? "") }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if friendUids.isEmpty {
            emptyState
        } else if posts.isEmpty {
            nothingYet
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if let hero = posts.first {
                        NavigationLink(value: hero) {
                            heroPost(hero)
                        }
                        .buttonStyle(.plain)
                    }
                    if posts.count > 1 {
                        ForEach(Array(paginatedRows), id: \.id) { row in
                            row.view
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.bottom, 140)
            }
        }
    }

    private var friendUidsKey: String { friendUids.sorted().joined(separator: ",") }

    // MARK: - Hero post (full-width)

    private func heroPost(_ post: FeedPost) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            PCCoverImage(url: post.recipe.coverPhotoURL,
                         placeholderLabel: "\(post.authorDisplayName) · \(post.recipe.title)",
                         height: 240)
            HStack(spacing: 10) {
                avatar(post.authorDisplayName, url: post.authorPhotoURL, size: 32)
                VStack(alignment: .leading, spacing: 0) {
                    Text(post.authorDisplayName)
                        .font(Theme.Fonts.ui(13, weight: .semibold))
                    Text("@\(post.authorHandle) · \(relative(post.createdAt))")
                        .font(Theme.Fonts.mono(10))
                        .foregroundStyle(Theme.Colors.ink3)
                }
                Spacer()
                if post.recipe.isHighProtein {
                    PCChip(text: "HP", style: .lime)
                }
            }
            Text(post.recipe.title)
                .font(Theme.Fonts.display(24))
                .tracking(-0.5)
            if let caption = post.caption, !caption.isEmpty {
                Text(caption)
                    .font(Theme.Fonts.ui(14))
                    .foregroundStyle(Theme.Colors.ink2)
                    .lineLimit(3)
            }
            HStack(spacing: 18) {
                metric(systemImage: "heart", count: post.likeCount, active: likedIds.contains(post.id))
                metric(systemImage: "bubble.left", count: post.commentCount, active: false)
                metric(systemImage: "bookmark", count: 0, active: false)
                Spacer()
            }
        }
        .padding(14)
        .background(Theme.Colors.paper)
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.l).stroke(Theme.Colors.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l))
    }

    private func avatar(_ name: String, url: URL?, size: CGFloat) -> some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img): img.resizable().scaledToFill()
                    default: Theme.Colors.indigo
                    }
                }
            } else {
                Theme.Colors.indigo
                    .overlay(Text(String(name.prefix(1)).uppercased())
                        .font(Theme.Fonts.display(14))
                        .foregroundStyle(.white))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private func metric(systemImage: String, count: Int, active: Bool) -> some View {
        HStack(spacing: 5) {
            Image(systemName: active ? "\(systemImage).fill" : systemImage)
                .font(.system(size: 12))
                .foregroundStyle(active ? .red : Theme.Colors.ink3)
            Text("\(count)")
                .font(Theme.Fonts.mono(11))
                .foregroundStyle(Theme.Colors.ink3)
        }
    }

    // MARK: - Mixed grid of remaining posts

    /// Group remaining posts into a mix of rows: quote-paired-with-photo,
    /// 2-col photo pairs, and standalone wide rows — a light magazine layout.
    private var paginatedRows: [RowItem] {
        var rows: [RowItem] = []
        var remaining = Array(posts.dropFirst())

        while !remaining.isEmpty {
            if remaining.count >= 2 {
                let a = remaining.removeFirst()
                let b = remaining.removeFirst()
                rows.append(RowItem(id: "\(a.id)|\(b.id)",
                                    view: AnyView(pairRow(a, b))))
            } else {
                let last = remaining.removeFirst()
                rows.append(RowItem(id: last.id,
                                    view: AnyView(wideRow(last))))
            }
        }
        return rows
    }

    private struct RowItem { let id: String; let view: AnyView }

    @ViewBuilder
    private func pairRow(_ a: FeedPost, _ b: FeedPost) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if let caption = a.caption, !caption.isEmpty, a.recipe.coverPhotoURL == nil {
                NavigationLink(value: a) { quoteTile(a) }.buttonStyle(.plain)
            } else {
                NavigationLink(value: a) { gridPost(a) }.buttonStyle(.plain)
            }
            NavigationLink(value: b) { gridPost(b) }.buttonStyle(.plain)
        }
    }

    private func gridPost(_ p: FeedPost) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            PCCoverImage(url: p.recipe.coverPhotoURL,
                         placeholderLabel: p.recipe.title,
                         height: 140)
            Text(p.recipe.title)
                .font(Theme.Fonts.ui(13, weight: .semibold))
                .foregroundStyle(Theme.Colors.ink)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Text("\(Int(p.recipe.macrosPerServing.proteinG))g P · \(Int(p.recipe.macrosPerServing.kcal)) kcal")
                .font(Theme.Fonts.mono(10))
                .foregroundStyle(Theme.Colors.ink3)
        }
        .padding(10)
        .background(Theme.Colors.paper)
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.m).stroke(Theme.Colors.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
    }

    private func quoteTile(_ p: FeedPost) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            PCEyebrow(text: "@\(p.authorHandle)", color: Color.white.opacity(0.7))
            Text("\"\(p.caption ?? p.recipe.title)\"")
                .font(Theme.Fonts.display(18))
                .tracking(-0.3)
                .foregroundStyle(.white)
                .lineLimit(5)
            Spacer(minLength: 0)
            PCEyebrow(text: "\(max(1, p.likeCount)) friends saved", color: Color.white.opacity(0.65))
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .frame(height: 240)
        .background(Theme.Colors.ink)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
    }

    private func wideRow(_ p: FeedPost) -> some View {
        NavigationLink(value: p) {
            HStack(spacing: 12) {
                PCCoverImage(url: p.recipe.coverPhotoURL,
                             placeholderLabel: String(p.recipe.title.prefix(6)),
                             height: 72)
                    .frame(width: 72)
                VStack(alignment: .leading, spacing: 2) {
                    PCEyebrow(text: p.recipe.sourceUserHandle.map { "adapted from @\($0)" } ?? "from @\(p.authorHandle)")
                    Text(p.recipe.title)
                        .font(Theme.Fonts.ui(14, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink)
                    Text("\(Int(p.recipe.macrosPerServing.proteinG))g P · \(Int(p.recipe.macrosPerServing.kcal)) kcal")
                        .font(Theme.Fonts.mono(10))
                        .foregroundStyle(Theme.Colors.ink3)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.Colors.ink3)
            }
            .padding(12)
            .background(Theme.Colors.paper)
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.m).stroke(Theme.Colors.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty states

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            PCEyebrow(text: "No friends yet")
            Text("Your kitchen, your crew.")
                .font(Theme.Fonts.display(26))
                .tracking(-0.6)
            Text("Add friends by their handle to see what they're cooking.")
                .font(Theme.Fonts.ui(14))
                .foregroundStyle(Theme.Colors.ink3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            PCButton(title: "Find friends", systemImage: "person.badge.plus", style: .indigo) {
                showingFriends = true
            }
            .padding(.horizontal, 60)
            Spacer()
        }
    }

    private var nothingYet: some View {
        VStack(spacing: 16) {
            Spacer()
            PCEyebrow(text: "No posts yet")
            Text("Nothing new.")
                .font(Theme.Fonts.display(26))
                .tracking(-0.6)
            Text("When your friends share recipes, you'll see them here.")
                .font(Theme.Fonts.ui(14))
                .foregroundStyle(Theme.Colors.ink3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    // MARK: - Data

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
        guard !friendUids.isEmpty else { posts = []; return }
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
        for post in posts.prefix(30) {
            if (try? await env.feed.hasLiked(postId: post.id, likerUid: uid)) == true {
                liked.insert(post.id)
            }
        }
        likedIds = liked
    }

    private func relative(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: Date())
    }
}
