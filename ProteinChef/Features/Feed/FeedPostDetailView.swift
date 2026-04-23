import SwiftUI

struct FeedPostDetailView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.userProfile) private var profile

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
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                authorHeader
                if let caption = post.caption, !caption.isEmpty {
                    Text(caption).font(.body)
                }
                recipeBlock
                actionRow
                commentsSection
            }
            .padding(.horizontal)
            .padding(.bottom, 120) // room for the comment bar
        }
        .safeAreaInset(edge: .bottom) { commentBar }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            async let a: () = subscribeComments()
            async let b: () = refreshLike()
            _ = await (a, b)
        }
        .alert("Error", isPresented: .constant(errorText != nil)) {
            Button("OK") { errorText = nil }
        } message: { Text(errorText ?? "") }
    }

    // MARK: - Sections

    private var authorHeader: some View {
        HStack(spacing: Theme.Spacing.s) {
            avatar
            VStack(alignment: .leading, spacing: 0) {
                Text(post.authorDisplayName).font(.subheadline.bold())
                Text("@\(post.authorHandle)").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(post.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.top, Theme.Spacing.s)
    }

    @ViewBuilder private var avatar: some View {
        if let url = post.authorPhotoURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img): img.resizable().scaledToFill()
                default: Color.secondary.opacity(0.1)
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())
        } else {
            Circle()
                .fill(Color.secondary.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(Image(systemName: "person.fill").foregroundStyle(.secondary))
        }
    }

    private var recipeBlock: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            if let url = post.recipe.coverPhotoURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img): img.resizable().scaledToFill()
                    default: Color.secondary.opacity(0.1)
                    }
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
            }
            Text(post.recipe.title).font(.title2.bold())
            HStack(spacing: Theme.Spacing.m) {
                macroChip("P", "\(Int(post.recipe.macrosPerServing.proteinG))g", Theme.Colors.protein)
                macroChip("C", "\(Int(post.recipe.macrosPerServing.carbsG))g", Theme.Colors.carbs)
                macroChip("F", "\(Int(post.recipe.macrosPerServing.fatG))g", Theme.Colors.fat)
                macroChip("kcal", "\(Int(post.recipe.macrosPerServing.kcal))", Theme.Colors.kcal)
            }
            Text("\(Int(post.recipe.servings)) servings · \(post.recipe.prepMinutes + post.recipe.cookMinutes) min total")
                .font(.caption).foregroundStyle(.secondary)

            if !post.recipe.ingredients.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ingredients").font(.headline).padding(.top, 4)
                    ForEach(post.recipe.ingredients) { ing in
                        Text("• \(ing.ingredientName) — \(Int(ing.quantityG)) g")
                            .font(.footnote)
                    }
                }
            }

            if !post.recipe.instructions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Instructions").font(.headline).padding(.top, 4)
                    ForEach(post.recipe.instructions) { step in
                        HStack(alignment: .top, spacing: 6) {
                            Text("\(step.order + 1).").fontWeight(.semibold)
                            Text(step.text)
                        }
                        .font(.footnote)
                    }
                }
            }
        }
    }

    private func macroChip(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.footnote.bold()).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.s))
    }

    private var actionRow: some View {
        HStack(spacing: Theme.Spacing.m) {
            Button {
                Task { await toggleLike() }
            } label: {
                Label("\(displayLikeCount)", systemImage: liked ? "heart.fill" : "heart")
                    .foregroundStyle(liked ? .red : .primary)
            }
            .buttonStyle(.bordered)

            if post.authorUid != profile?.id {
                Button {
                    Task { await saveCopy() }
                } label: {
                    Label(savedCopy ? "Saved" : "Save to my recipes",
                          systemImage: savedCopy ? "checkmark" : "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.Colors.protein)
                .disabled(savedCopy || savingCopy)
            }

            Spacer()
        }
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("Comments").font(.headline)
            if comments.isEmpty {
                Text("Be the first to comment.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(comments) { comment in
                    commentRow(comment)
                }
            }
        }
    }

    private func commentRow(_ c: FeedComment) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.s) {
            Circle()
                .fill(Color.secondary.opacity(0.15))
                .frame(width: 28, height: 28)
                .overlay(Text(String(c.authorDisplayName.prefix(1))).font(.caption))
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(c.authorDisplayName).font(.caption.bold())
                    Text("@\(c.authorHandle)").font(.caption2).foregroundStyle(.secondary)
                    Spacer()
                }
                Text(c.text).font(.footnote)
            }
            if c.authorUid == profile?.id {
                Button {
                    Task { await deleteComment(c) }
                } label: {
                    Image(systemName: "xmark.circle").font(.caption).foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var commentBar: some View {
        HStack {
            TextField("Write a comment", text: $newComment, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
            Button {
                Task { await postComment() }
            } label: {
                if isPostingComment {
                    ProgressView()
                } else {
                    Image(systemName: "paperplane.fill")
                }
            }
            .disabled(newComment.trimmingCharacters(in: .whitespaces).isEmpty || isPostingComment)
        }
        .padding()
        .background(.regularMaterial)
    }

    // MARK: - Actions

    private func subscribeComments() async {
        do {
            for try await list in env.feed.listCommentsStream(postId: post.id) {
                comments = list
            }
        } catch {
            errorText = error.localizedDescription
        }
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
            if liked && !wasLiked {
                likeDelta += 1
            } else if !liked && wasLiked {
                likeDelta -= 1
            }
        } catch {
            errorText = error.localizedDescription
        }
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
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func deleteComment(_ c: FeedComment) async {
        do {
            try await env.feed.deleteComment(postId: post.id, commentId: c.id)
        } catch {
            errorText = error.localizedDescription
        }
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
        } catch {
            errorText = error.localizedDescription
        }
    }
}
