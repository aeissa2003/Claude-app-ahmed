import SwiftUI

/// Step 1 of logging a recipe meal: pick which recipe. Tapping a row pushes into LogRecipeSheet.
struct RecipePickerForLoggingSheet: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    let uid: String
    let day: Date
    var initialMealType: MealType? = nil
    let onLogged: () -> Void

    @State private var recipes: [Recipe] = []
    @State private var query: String = ""
    @State private var chosen: Recipe?

    var filtered: [Recipe] {
        guard !query.isEmpty else { return recipes }
        let q = query.lowercased()
        return recipes.filter { $0.title.lowercased().contains(q) || $0.tags.contains(where: { $0.lowercased().contains(q) }) }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { recipe in
                Button {
                    chosen = recipe
                } label: {
                    HStack(spacing: Theme.Spacing.m) {
                        thumb(recipe)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(recipe.title).font(.subheadline)
                            Text("\(Int(recipe.macrosPerServing.proteinG))g P · \(Int(recipe.macrosPerServing.kcal)) kcal / serving")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .searchable(text: $query, prompt: "Search your recipes")
            .navigationTitle("Pick a recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task(id: uid) {
                do {
                    for try await list in env.recipes.listStream(ownerUid: uid) {
                        recipes = list
                    }
                } catch {
                    recipes = []
                }
            }
            .sheet(item: $chosen) { recipe in
                LogRecipeSheet(uid: uid, day: day, recipe: recipe, initialServings: 1) {
                    chosen = nil
                    onLogged()
                    dismiss()
                }
                .environment(env)
            }
        }
    }

    @ViewBuilder private func thumb(_ recipe: Recipe) -> some View {
        if let url = recipe.coverPhotoURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img): img.resizable().scaledToFill()
                default: Color.secondary.opacity(0.1)
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.s))
        } else {
            RoundedRectangle(cornerRadius: Theme.Radius.s)
                .fill(Color.secondary.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(Image(systemName: "fork.knife").foregroundStyle(.secondary))
        }
    }
}
