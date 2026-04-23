import SwiftUI

struct FeedPostDetailView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.userProfile) private var profile
    @Environment(\.dismiss) private var dismiss

    let post: FeedPost
    @State var liked: Bool
    @State private var likeDelta: Int = 0
    @State private var comments: [FeedComment] = []
    @State private var newComment: String = ""
    @State private var isPostingComment = false
    @State private var savedCopy = false
    @State private var savingCopy = false
    @State private var errorText: String?

    init(post: FeedPost, initiallyLiked: Bool) {
        self.post = post
        _liked = State(initialValue: initiallyLiked)
    }

    private var displayLikeCount: Int { post.likeCount + likeDelta }

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.Colors.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    cover
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        authorRow
                        titleAndCaption
                        recipeAttachment
                        actionRow
                        commentsSection
                    }
                    .padding(.horizontal, Theme.Spacing.l)
                }
                .padding(.bottom, 120)
            }
            commentBar
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            async let a: () = subscribeComments()
            async let b: () = refreshLike()
            _ = await (a, b)
        }
        .alert("Error", isPresented: .constant(errorText != nil)) {
            Button("OK") { errorText = nil }
        } message: { Text(errorText ?? "") }
    }

    // MARK: - Cover

    private var cover: some View {
        ZStack(alignment: .topLeading) {
            PCCoverImage(url: post.recipe.coverPhotoURL,
                         placeholderLabel: "\(post.authorDisplayName) · \(post.recipe.title)",
                         height: 320)
            PCIconButton(systemName: "chevron.left", variant: .paper) { dismiss() }
                .padding(.top, 56)
                .padding(.leading, Theme.Spacing.l)
        }
    }

    // MARK: - Author

    private var authorRow: some View {
        HStack(spacing: 12) {
            avatar(size: 44)
            VStack(alignment: .leading, spacing: 0) {
                Text(post.authorDisplayName).font(Theme.Fonts.ui(15, weight: .semibold))
                Text("@\(post.authorHandle) · \(relative(post.createdAt))")
                    .font(Theme.Fonts.mono(11))
                    .foregroundStyle(Theme.Colors.ink3)
            }
            Spacer()
            if post.authorUid != profile?.id {
                PCChip(text: "Follow", style: .active)
            }
        }
    }

    @ViewBuilder
    private func avatar(size: CGFloat) -> some View {
        if let url = post.authorPhotoURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img): img.resizable().scaledToFill()
                default: Theme.Colors.indigo
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        } else {
            Circle()
                .fill(Theme.Colors.indigo)
                .frame(width: size, height: size)
                .overlay(Text(String(post.authorDisplayName.prefix(1)).uppercased())
                    .font(Theme.Fonts.display(16))
                    .foregroundStyle(.white))
        }
    }

    // MARK: - Title + caption

    private var titleAndCaption: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(post.recipe.title)
                .font(Theme.Fonts.display(28))
                .tracking(-0.7)
            if let caption = post.caption, !caption.isEmpty {
                Text(caption)
                    .font(Theme.Fonts.ui(15))
                    .foregroundStyle(Theme.Colors.ink2)
            }
        }
    }

    // MARK: - Recipe attachment (ink card)

    private var recipeAttachment: some View {
        PCCard(style: .ink, padding: 14) {
            HStack(spacing: 12) {
                PCCoverImage(url: post.recipe.coverPhotoURL,
                             placeholderLabel: String(post.recipe.title.prefix(6)),
                             height: 80)
                    .frame(width: 80)
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.recipe.title)
                        .font(Theme.Fonts.ui(14, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Text("\(Int(post.recipe.macrosPerServing.proteinG))g P · \(Int(post.recipe.macrosPerServing.kcal)) kcal")
                        .font(Theme.Fonts.mono(10))
                        .foregroundStyle(Color.white.opacity(0.65))
                }
                Spacer()
                if post.authorUid != profile?.id {
                    Button {
                        Task { await saveCopy() }
                    } label: {
                        Text(savedCopy ? "Saved" : "Save copy")
                            .font(Theme.Fonts.ui(12, weight: .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Theme.Colors.lime)
                            .foregroundStyle(Theme.Colors.limeInk)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(savedCopy || savingCopy)
                }
            }
        }
    }

    // MARK: - Action row

    private var actionRow: some View {
        HStack(spacing: 18) {
            actionButton(
                systemImage: liked ? "heart.fill" : "heart",
                text: "\(displayLikeCount)",
                tint: liked ? .red : Theme.Colors.ink,
                action: { Task { await toggleLike() } }
            )
            actionButton(
                systemImage: "bubble.left",
                text: "\(post.commentCount)",
                tint: Theme.Colors.ink,
                action: {}
            )
            actionButton(
                systemImage: "square.and.arrow.up",
                text: "Share",
                tint: Theme.Colors.ink,
                action: {}
            )
            Spacer()
        }
        .padding(.top, 4)
    }

    private func actionButton(systemImage: String,
                              text: String,
                              tint: Color,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage).font(.system(size: 14))
                Text(text).font(Theme.Fonts.mono(12, weight: .semibold))
            }
            .foregroundStyle(tint)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Comments

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("Comments").font(Theme.Fonts.sectionTitle).tracking(-0.5)
            if comments.isEmpty {
                Text("Be the first to comment.")
                    .font(Theme.Fonts.ui(13))
                    .foregroundStyle(Theme.Colors.ink3)
            } else {
                VStack(spacing: 12) {
                    ForEach(comments) { commentRow($0) }
                }
            }
        }
    }

    private func commentRow(_ c: FeedComment) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Theme.Colors.indigo)
                .frame(width: 32, height: 32)
                .overlay(Text(String(c.authorDisplayName.prefix(1)).uppercased())
                    .font(Theme.Fonts.display(12))
                    .foregroundStyle(.white))
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(c.authorDisplayName).font(Theme.Fonts.ui(13, weight: .semibold))
                    Text("@\(c.authorHandle)").font(Theme.Fonts.mono(10)).foregroundStyle(Theme.Colors.ink3)
                    Spacer()
                    if c.authorUid == profile?.id {
                        Button { Task { await deleteComment(c) } } label: {
                            Image(systemName: "xmark").font(.system(size: 10)).foregroundStyle(Theme.Colors.ink3)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Text(c.text).font(Theme.Fonts.ui(13))
            }
        }
    }

    // MARK: - Comment bar

    private var commentBar: some View {
        HStack(spacing: 10) {
            TextField("Write a comment", text: $newComment, axis: .vertical)
                .font(Theme.Fonts.ui(14))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Theme.Colors.paper)
                .overlay(Capsule().stroke(Theme.Colors.line, lineWidth: 1))
                .clipShape(Capsule())
                .lineLimit(1...4)
            Button {
                Task { await postComment() }
            } label: {
                Group {
                    if isPostingComment { ProgressView().tint(.white) }
                    else { Image(systemName: "paperplane.fill").foregroundStyle(.white) }
                }
                .frame(width: 44, height: 44)
                .background(newComment.trimmingCharacters(in: .whitespaces).isEmpty ? Theme.Colors.ink3 : Theme.Colors.indigo)
                .clipShape(Circle())
            }
            .disabled(newComment.trimmingCharacters(in: .whitespaces).isEmpty || isPostingComment)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.vertical, Theme.Spacing.s)
        .background(
            Theme.Colors.bg.opacity(0.96)
                .background(.ultraThinMaterial)
                .overlay(Divider().overlay(Theme.Colors.line), alignment: .top)
        )
    }

    // MARK: - Helpers

    private func relative(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Actions

    private func subscribeComments() async {
        do {
            for try await list in env.feed.listCommentsStream(postId: post.id) {
                comments = list
            }
        } catch { errorText = error.localizedDescription }
    }

    private func refreshLike() async {
        guard let uid = env.auth.currentUid else { return }
        liked = (try? await env.feed.hasLiked(postId: post.id, likerUid: uid)) ?? false
    }

    private func toggleLike() async {
        guard let uid = env.auth.currentUid else { return }
        let wasLiked = liked
        do {
            liked = try await env.feed.toggleLike(postId: post.id, likerUid: uid)
            if liked && !wasLiked { likeDelta += 1 }
            else if !liked && wasLiked { likeDelta -= 1 }
        } catch { errorText = error.localizedDescription }
    }

    private func postComment() async {
        guard let me = profile else { return }
        let text = newComment.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        isPostingComment = true
        defer { isPostingComment = false }
        do {
            try await env.feed.addComment(postId: post.id, author: me, text: text)
            newComment = ""
        } catch { errorText = error.localizedDescription }
    }

    private func deleteComment(_ c: FeedComment) async {
        do { try await env.feed.deleteComment(postId: post.id, commentId: c.id) }
        catch { errorText = error.localizedDescription }
    }

    private func saveCopy() async {
        guard let me = profile else { return }
        savingCopy = true
        defer { savingCopy = false }
        let original = post.recipe
        let now = Date()
        let copy = Recipe(
            id: UUID().uuidString,
            ownerUid: me.id,
            title: original.title,
            coverPhotoURL: original.coverPhotoURL,
            galleryPhotoURLs: original.galleryPhotoURLs,
            instructions: original.instructions,
            prepMinutes: original.prepMinutes,
            cookMinutes: original.cookMinutes,
            servings: original.servings,
            tags: original.tags,
            ingredients: original.ingredients,
            macrosTotal: original.macrosTotal,
            macrosPerServing: original.macrosPerServing,
            isHighProtein: original.isHighProtein,
            privacy: .private,
            sourceRecipeId: original.id,
            sourceUserId: post.authorUid,
            sourceUserHandle: post.authorHandle,
            createdAt: now,
            updatedAt: now
        )
        do {
            try await env.recipes.save(copy)
            savedCopy = true
        } catch { errorText = error.localizedDescription }
    }
}
