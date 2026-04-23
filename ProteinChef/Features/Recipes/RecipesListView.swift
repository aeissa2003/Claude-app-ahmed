import SwiftUI

struct RecipesListView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.userProfile) private var profile

    @State private var recipes: [Recipe] = []
    @State private var loadError: String?
    @State private var showingEditor = false

    var body: some View {
        NavigationStack {
            Group {
                if recipes.isEmpty {
                    ContentUnavailableView {
                        Label("No recipes yet", systemImage: "fork.knife")
                    } description: {
                        Text("Tap + to create your first high-protein recipe.")
                    } actions: {
                        Button("Create recipe") { showingEditor = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(recipes) { recipe in
                            NavigationLink(value: recipe) {
                                RecipeListRow(recipe: recipe)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("Recipes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingEditor = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add recipe")
                }
            }
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .sheet(isPresented: $showingEditor) {
                if let uid = env.auth.currentUid {
                    RecipeEditorView(uid: uid)
                        .environment(env)
                }
            }
            .task(id: env.auth.currentUid ?? "") {
                await subscribe()
            }
            .alert("Couldn’t load recipes", isPresented: .constant(loadError != nil)) {
                Button("OK") { loadError = nil }
            } message: { Text(loadError ?? "") }
        }
    }

    private func subscribe() async {
        guard let uid = env.auth.currentUid else { return }
        do {
            for try await list in env.recipes.listStream(ownerUid: uid) {
                recipes = list
            }
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func delete(at offsets: IndexSet) {
        guard let uid = env.auth.currentUid else { return }
        let toDelete = offsets.map { recipes[$0] }
        Task {
            for recipe in toDelete {
                try? await env.recipes.delete(ownerUid: uid, recipeId: recipe.id)
            }
        }
    }
}

struct RecipeListRow: View {
    let recipe: Recipe

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            thumb
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(recipe.title).font(.headline)
                    if recipe.isHighProtein {
                        Text("HP")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Theme.Colors.protein.opacity(0.18))
                            .foregroundStyle(Theme.Colors.protein)
                            .clipShape(Capsule())
                    }
                }
                Text("\(Int(recipe.macrosPerServing.proteinG))g protein · \(Int(recipe.macrosPerServing.kcal)) kcal / serving")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if !recipe.tags.isEmpty {
                    Text(recipe.tags.prefix(3).map { "#\($0)" }.joined(separator: " "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder private var thumb: some View {
        if let url = recipe.coverPhotoURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img): img.resizable().scaledToFill()
                default: Color.secondary.opacity(0.1)
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.s))
        } else {
            RoundedRectangle(cornerRadius: Theme.Radius.s)
                .fill(Color.secondary.opacity(0.1))
                .frame(width: 56, height: 56)
                .overlay(Image(systemName: "fork.knife").foregroundStyle(.secondary))
        }
    }
}
