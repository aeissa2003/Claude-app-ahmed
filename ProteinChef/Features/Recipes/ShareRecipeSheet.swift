import SwiftUI

/// Compact sheet: add an optional caption and post the recipe to the friends feed.
struct ShareRecipeSheet: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.userProfile) private var profile
    @Environment(\.dismiss) private var dismiss

    let recipe: Recipe

    @State private var caption: String = ""
    @State private var isPosting = false
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Recipe") {
                    HStack(spacing: Theme.Spacing.s) {
                        thumb
                        VStack(alignment: .leading, spacing: 2) {
                            Text(recipe.title).font(.subheadline.bold())
                            Text("\(Int(recipe.macrosPerServing.proteinG))g P · \(Int(recipe.macrosPerServing.kcal)) kcal / serving")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Caption (optional)") {
                    TextField("Say something about this recipe…", text: $caption, axis: .vertical)
                        .lineLimit(1...6)
                }
                Section {
                    Text("Your friends will see this in their feed. They can like, comment, and save a copy.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Share to feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        Task { await share() }
                    }
                    .disabled(isPosting)
                }
            }
            .alert("Couldn’t post", isPresented: .constant(errorText != nil)) {
                Button("OK") { errorText = nil }
            } message: { Text(errorText ?? "") }
        }
    }

    @ViewBuilder private var thumb: some View {
        if let url = recipe.coverPhotoURL {
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

    private func share() async {
        guard let me = profile else { return }
        isPosting = true
        defer { isPosting = false }
        do {
            _ = try await env.feed.sharePost(author: me, recipe: recipe, caption: caption)
            dismiss()
        } catch {
            errorText = error.localizedDescription
        }
    }
}
