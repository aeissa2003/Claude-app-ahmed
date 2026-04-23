import SwiftUI

struct RecipeDetailView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.userProfile) private var profile
    let recipe: Recipe
    @State private var showingEditor = false
    @State private var showingShareSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                cover
                header
                macroRow
                if !recipe.tags.isEmpty { tagRow }
                ingredientsSection
                instructionsSection
                if !recipe.galleryPhotoURLs.isEmpty { gallerySection }
                if let handle = recipe.sourceUserHandle { attribution(handle: handle) }
            }
            .padding(.horizontal)
        }
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingEditor = true
                    } label: { Label("Edit", systemImage: "pencil") }
                    if profile?.id == recipe.ownerUid {
                        Button {
                            showingShareSheet = true
                        } label: { Label("Share to feed", systemImage: "square.and.arrow.up") }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            RecipeEditorView(uid: recipe.ownerUid, editing: recipe)
                .environment(env)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareRecipeSheet(recipe: recipe).environment(env)
        }
    }

    @ViewBuilder private var cover: some View {
        if let url = recipe.coverPhotoURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img): img.resizable().scaledToFill()
                default: Color.secondary.opacity(0.1)
                }
            }
            .frame(height: 260)
            .frame(maxWidth: .infinity)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l))
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(recipe.title).font(.title2.bold())
            Text("\(Int(recipe.servings)) servings · \(recipe.prepMinutes + recipe.cookMinutes) min total")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var macroRow: some View {
        HStack(spacing: Theme.Spacing.m) {
            macro(label: "Protein", value: "\(Int(recipe.macrosPerServing.proteinG))g", color: Theme.Colors.protein)
            macro(label: "Carbs",   value: "\(Int(recipe.macrosPerServing.carbsG))g",   color: Theme.Colors.carbs)
            macro(label: "Fat",     value: "\(Int(recipe.macrosPerServing.fatG))g",     color: Theme.Colors.fat)
            macro(label: "Calories",value: "\(Int(recipe.macrosPerServing.kcal))",      color: Theme.Colors.kcal)
        }
    }

    private func macro(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.headline).foregroundStyle(color)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.s)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.s))
    }

    private var tagRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(recipe.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("Ingredients").font(.headline)
            ForEach(recipe.ingredients) { ing in
                HStack(spacing: Theme.Spacing.s) {
                    if let url = ing.photoURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img): img.resizable().scaledToFill()
                            default: Color.secondary.opacity(0.1)
                            }
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.s))
                    } else {
                        RoundedRectangle(cornerRadius: Theme.Radius.s)
                            .fill(Color.secondary.opacity(0.1))
                            .frame(width: 40, height: 40)
                    }
                    VStack(alignment: .leading) {
                        Text(ing.ingredientName).font(.subheadline)
                        Text("\(formatted(ing.displayQuantity)) \(ing.displayUnit) · \(Int(ing.macrosAtEntry.proteinG))g P")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Divider()
            }
        }
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("Instructions").font(.headline)
            ForEach(recipe.instructions) { step in
                HStack(alignment: .top, spacing: Theme.Spacing.s) {
                    Text("\(step.order + 1).").fontWeight(.semibold)
                    Text(step.text)
                }
            }
        }
    }

    private var gallerySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("Gallery").font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.s) {
                    ForEach(recipe.galleryPhotoURLs, id: \.self) { url in
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img): img.resizable().scaledToFill()
                            default: Color.secondary.opacity(0.1)
                            }
                        }
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.s))
                    }
                }
            }
        }
    }

    private func attribution(handle: String) -> some View {
        Text("Adapted from @\(handle)")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func formatted(_ q: Double) -> String {
        q.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(q))
            : String(format: "%.2f", q)
    }
}
