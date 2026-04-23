import SwiftUI

struct RecipeDetailView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.userProfile) private var profile
    @Environment(\.dismiss) private var dismiss
    let recipe: Recipe

    @State private var showingEditor = false
    @State private var showingShareSheet = false
    @State private var showingLogSheet = false
    @State private var scale: Scale = .x1

    enum Scale: Hashable { case x1, x2, x4
        var multiplier: Double {
            switch self { case .x1: 1; case .x2: 2; case .x4: 4 }
        }
        var label: String {
            switch self { case .x1: "1×"; case .x2: "2×"; case .x4: "4×" }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.Colors.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    cover
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        chipRow
                        titleBlock
                        macroStrip
                        ingredientsSection
                        methodSection
                        if !recipe.galleryPhotoURLs.isEmpty { gallerySection }
                        if let handle = recipe.sourceUserHandle { attribution(handle: handle) }
                    }
                    .padding(.horizontal, Theme.Spacing.l)
                }
                .padding(.bottom, 140)
            }

            stickyFooter
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingEditor) {
            RecipeEditorView(uid: recipe.ownerUid, editing: recipe).environment(env)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareRecipeSheet(recipe: recipe).environment(env)
        }
        .sheet(isPresented: $showingLogSheet) {
            if let uid = env.auth.currentUid {
                LogRecipeSheet(uid: uid, day: Date(), recipe: recipe, initialServings: 1)
                    .environment(env)
            }
        }
    }

    // MARK: - Cover

    private var cover: some View {
        ZStack(alignment: .top) {
            PCCoverImage(url: recipe.coverPhotoURL,
                         placeholderLabel: "\(recipe.title) · cover",
                         height: 280)
                .clipShape(RoundedRectangle(cornerRadius: 0))
            HStack {
                PCIconButton(systemName: "chevron.left", variant: .paper) { dismiss() }
                Spacer()
                HStack(spacing: 8) {
                    PCIconButton(systemName: "bookmark", variant: .paper) {}
                    PCIconButton(systemName: "square.and.arrow.up", variant: .paper) {
                        showingShareSheet = true
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.top, 56)
        }
    }

    // MARK: - Chip row

    private var chipRow: some View {
        HStack(spacing: 8) {
            if recipe.isHighProtein {
                PCChip(text: "high protein", style: .lime)
            }
            ForEach(recipe.tags.prefix(3), id: \.self) { tag in
                PCChip(text: tag, style: .neutral)
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(recipe.title)
                .font(Theme.Fonts.display(32))
                .tracking(-0.8)
                .foregroundStyle(Theme.Colors.ink)
            PCEyebrow(text: metaLabel)
        }
    }

    private var metaLabel: String {
        let who = profile?.id == recipe.ownerUid ? "Your recipe" : "Shared recipe"
        let updated = relative(recipe.updatedAt).uppercased()
        return "\(who) · Updated \(updated)"
    }

    private func relative(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Macro strip

    private var macroStrip: some View {
        PCCard(style: .paper, padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    PCEyebrow(text: "Per serving")
                    Spacer()
                    PCSegmented(selection: $scale, options: [
                        (.x1, "1×"), (.x2, "2×"), (.x4, "4×")
                    ])
                    .frame(width: 150)
                }
                HStack(spacing: 0) {
                    macroStat("\(scaled(recipe.macrosPerServing.proteinG))", "g", "Protein", Theme.Colors.protein)
                    macroStat("\(scaled(recipe.macrosPerServing.carbsG))",   "g", "Carbs",   Theme.Colors.carbs)
                    macroStat("\(scaled(recipe.macrosPerServing.fatG))",    "g", "Fat",     Theme.Colors.fat)
                    macroStat("\(scaledKcal(recipe.macrosPerServing.kcal))", "",  "kcal",   Theme.Colors.ink)
                }
                Divider().overlay(Theme.Colors.line)
                HStack(spacing: 24) {
                    metaChip(systemImage: "clock", text: "\(recipe.prepMinutes + recipe.cookMinutes) min")
                    metaChip(systemImage: "person.2", text: "\(Int(recipe.servings)) servings")
                    metaChip(systemImage: "flame", text: "medium")
                }
            }
        }
    }

    private func scaled(_ v: Double) -> Int { Int(v * scale.multiplier) }
    private func scaledKcal(_ v: Double) -> Int { Int(v * scale.multiplier) }

    private func macroStat(_ value: String, _ unit: String, _ label: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value).font(Theme.Fonts.display(28)).tracking(-0.5).foregroundStyle(color)
                if !unit.isEmpty {
                    Text(unit).font(Theme.Fonts.ui(11)).foregroundStyle(Theme.Colors.ink3)
                }
            }
            PCEyebrow(text: label)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metaChip(systemImage: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage).font(.system(size: 11))
            Text(text).font(Theme.Fonts.mono(11)).foregroundStyle(Theme.Colors.ink3)
        }
    }

    // MARK: - Ingredients

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("Ingredients").font(Theme.Fonts.sectionTitle).tracking(-0.5)
            VStack(spacing: 10) {
                ForEach(Array(recipe.ingredients.enumerated()), id: \.element.id) { idx, ing in
                    ingredientRow(index: idx + 1, ing: ing)
                }
            }
        }
    }

    private func ingredientRow(index: Int, ing: RecipeIngredient) -> some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(Theme.Fonts.display(14))
                .foregroundStyle(Theme.Colors.protein)
                .frame(width: 26, height: 26)
                .background(Theme.Colors.protein.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(ing.ingredientName).font(Theme.Fonts.bodyStrong)
                Text("\(Int(ing.quantityG)) g").font(Theme.Fonts.mono(11)).foregroundStyle(Theme.Colors.ink3)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 0) {
                Text("\(Int(ing.macrosAtEntry.proteinG))g")
                    .font(Theme.Fonts.display(16))
                    .foregroundStyle(Theme.Colors.protein)
                Text("\(Int(ing.macrosAtEntry.kcal)) kcal")
                    .font(Theme.Fonts.mono(10))
                    .foregroundStyle(Theme.Colors.ink3)
            }
        }
        .padding(12)
        .background(Theme.Colors.paper)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.m)
                .stroke(Theme.Colors.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
    }

    // MARK: - Method

    private var methodSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("Method").font(Theme.Fonts.sectionTitle).tracking(-0.5)
            VStack(spacing: 10) {
                ForEach(recipe.instructions) { step in
                    methodCard(step)
                }
            }
        }
    }

    private func methodCard(_ step: RecipeStep) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(String(format: "%02d", step.order + 1))
                .font(Theme.Fonts.display(28))
                .foregroundStyle(Theme.Colors.indigo)
            Text(step.text)
                .font(Theme.Fonts.ui(15))
                .foregroundStyle(Theme.Colors.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(Theme.Colors.paper)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.m)
                .stroke(Theme.Colors.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
    }

    // MARK: - Gallery + attribution

    private var gallerySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("Gallery").font(Theme.Fonts.sectionTitle).tracking(-0.5)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(recipe.galleryPhotoURLs, id: \.self) { url in
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img): img.resizable().scaledToFill()
                            default: Theme.Colors.ink.opacity(0.05)
                            }
                        }
                        .frame(width: 140, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
                    }
                }
            }
        }
    }

    private func attribution(handle: String) -> some View {
        Text("Adapted from @\(handle)")
            .font(Theme.Fonts.mono(11))
            .foregroundStyle(Theme.Colors.ink3)
            .padding(.top, Theme.Spacing.s)
    }

    // MARK: - Sticky footer

    private var stickyFooter: some View {
        HStack(spacing: 10) {
            PCIconButton(systemName: "pencil", variant: .paper) {
                showingEditor = true
            }
            PCButton(title: "Log this meal · +\(Int(recipe.macrosPerServing.proteinG))g P",
                     style: .indigo) {
                showingLogSheet = true
            }
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.vertical, Theme.Spacing.m)
        .background(
            Theme.Colors.bg.opacity(0.96)
                .background(.ultraThinMaterial)
                .overlay(
                    Divider().overlay(Theme.Colors.line),
                    alignment: .top
                )
        )
    }
}
