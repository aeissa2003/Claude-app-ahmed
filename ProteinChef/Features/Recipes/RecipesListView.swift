import SwiftUI

struct RecipesListView: View {
    @Environment(AppEnvironment.self) private var env

    @State private var recipes: [Recipe] = []
    @State private var loadError: String?
    @State private var showingEditor = false
    @State private var filter: Filter = .all

    enum Filter: String, CaseIterable, Hashable {
        case all, highProtein, breakfast, lunch, dinner, snack, batch

        var label: String {
            switch self {
            case .all: return "All"
            case .highProtein: return "High Protein"
            case .breakfast: return "Breakfast"
            case .lunch: return "Lunch"
            case .dinner: return "Dinner"
            case .snack: return "Snack"
            case .batch: return "Batch"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Theme.Colors.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    PCAppBar(title: "Recipes",
                             eyebrow: "Kitchen · \(recipes.count) saved") {
                        HStack(spacing: 8) {
                            PCIconButton(systemName: "magnifyingglass", variant: .paper) {}
                            PCIconButton(systemName: "plus", variant: .ink) {
                                showingEditor = true
                            }
                        }
                    }
                    content
                }
            }
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .sheet(isPresented: $showingEditor) {
                if let uid = env.auth.currentUid {
                    RecipeEditorView(uid: uid).environment(env)
                }
            }
            .task(id: env.auth.currentUid ?? "") { await subscribe() }
            .alert("Couldn’t load recipes", isPresented: .constant(loadError != nil)) {
                Button("OK") { loadError = nil }
            } message: { Text(loadError ?? "") }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if recipes.isEmpty {
            emptyState
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    filterRow
                    if let hero = filtered.first {
                        NavigationLink(value: hero) {
                            featuredCard(hero)
                        }
                        .buttonStyle(.plain)
                    }
                    if filtered.count > 1 {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12),
                                             GridItem(.flexible(), spacing: 12)],
                                  alignment: .leading,
                                  spacing: 12) {
                            ForEach(Array(filtered.dropFirst())) { recipe in
                                NavigationLink(value: recipe) {
                                    gridCard(recipe)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        Task { await delete(recipe) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.bottom, 140)
            }
        }
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Filter.allCases, id: \.self) { f in
                    PCChip(text: f.label,
                           style: filter == f ? .active : .neutral) {
                        filter = f
                    }
                }
            }
        }
    }

    private var filtered: [Recipe] {
        switch filter {
        case .all: return recipes
        case .highProtein: return recipes.filter { $0.isHighProtein }
        default:
            let tag = filter.label.lowercased()
            return recipes.filter { $0.tags.map { $0.lowercased() }.contains(tag) }
        }
    }

    // MARK: - Featured hero card

    private func featuredCard(_ r: Recipe) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            PCCoverImage(url: r.coverPhotoURL,
                         placeholderLabel: "Hero · \(r.title)",
                         height: 220)
            HStack(spacing: 8) {
                if r.isHighProtein {
                    PCChip(text: "high protein", style: .lime)
                }
                ForEach(r.tags.prefix(2), id: \.self) { tag in
                    PCChip(text: tag, style: .neutral)
                }
            }
            Text(r.title)
                .font(Theme.Fonts.display(28))
                .tracking(-0.8)
                .foregroundStyle(Theme.Colors.ink)

            HStack(spacing: 0) {
                featuredStat(value: "\(Int(r.macrosPerServing.proteinG))",
                             unit: "g P",
                             label: "per serving",
                             color: Theme.Colors.protein)
                Divider().frame(width: 1).overlay(Theme.Colors.line)
                featuredStat(value: "\(Int(r.macrosPerServing.kcal))",
                             unit: "kcal",
                             label: "energy",
                             color: Theme.Colors.ink)
                Divider().frame(width: 1).overlay(Theme.Colors.line)
                featuredStat(value: "\(r.prepMinutes + r.cookMinutes)",
                             unit: "min",
                             label: "time",
                             color: Theme.Colors.ink)
            }
        }
        .padding(18)
        .background(Theme.Colors.paper)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.l)
                .stroke(Theme.Colors.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l))
    }

    private func featuredStat(value: String,
                              unit: String,
                              label: String,
                              color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value).font(Theme.Fonts.display(26)).foregroundStyle(color)
                Text(unit).font(Theme.Fonts.ui(10)).foregroundStyle(Theme.Colors.ink3)
            }
            PCEyebrow(text: label)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
    }

    // MARK: - Grid card

    private func gridCard(_ r: Recipe) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topLeading) {
                PCCoverImage(url: r.coverPhotoURL,
                             placeholderLabel: String(r.title.prefix(8)),
                             height: 130)
                if r.isHighProtein {
                    Text("HP")
                        .font(Theme.Fonts.mono(9, weight: .semibold))
                        .tracking(0.8)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Theme.Colors.lime)
                        .foregroundStyle(Theme.Colors.limeInk)
                        .clipShape(Capsule())
                        .padding(8)
                }
            }
            Text(r.title)
                .font(Theme.Fonts.ui(14, weight: .semibold))
                .foregroundStyle(Theme.Colors.ink)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Text("\(Int(r.macrosPerServing.proteinG))g P · \(r.prepMinutes + r.cookMinutes)m")
                .font(Theme.Fonts.mono(10))
                .foregroundStyle(Theme.Colors.ink3)
        }
        .padding(10)
        .background(Theme.Colors.paper)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.m)
                .stroke(Theme.Colors.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            PCEyebrow(text: "No recipes yet")
            Text("Start your kitchen.")
                .font(Theme.Fonts.display(26))
                .tracking(-0.6)
            Text("Create your first high-protein recipe. Add ingredients, macros auto-calculate, and you can log meals from it.")
                .font(Theme.Fonts.ui(14))
                .foregroundStyle(Theme.Colors.ink3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            PCButton(title: "Create recipe", systemImage: "plus", style: .indigo) {
                showingEditor = true
            }
            .padding(.horizontal, 60)
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.l)
    }

    // MARK: - Data

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

    private func delete(_ recipe: Recipe) async {
        guard let uid = env.auth.currentUid else { return }
        try? await env.recipes.delete(ownerUid: uid, recipeId: recipe.id)
    }
}
