import SwiftUI

struct DayDashboardView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.userProfile) private var profile
    let day: Date

    @State private var vm: DayDashboardViewModel?
    @State private var suggestionTapped: RecipeSuggestion.Scored?

    var body: some View {
        Group {
            if let vm {
                content(vm: vm)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task(id: env.auth.currentUid ?? "") {
            guard let uid = env.auth.currentUid else { return }
            let model = DayDashboardViewModel(
                uid: uid,
                day: day,
                mealRepo: env.mealLogs,
                recipeRepo: env.recipes
            )
            vm = model
            async let a: () = model.subscribeMeals()
            async let b: () = model.subscribeRecipes()
            _ = await (a, b)
        }
    }

    @ViewBuilder
    private func content(vm: DayDashboardViewModel) -> some View {
        let proteinGoal = profile?.proteinGoalG ?? 0
        let calorieGoal = profile?.calorieGoalKcal ?? 0

        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                MacroRingsRow(
                    consumed: vm.consumed,
                    proteinGoalG: proteinGoal,
                    calorieGoalKcal: calorieGoal,
                    carbsGoalG: nil,
                    fatGoalG: nil
                )
                .padding(.top, Theme.Spacing.s)

                remainingSummary(vm: vm, proteinGoal: proteinGoal, calorieGoal: calorieGoal)

                ForEach(MealType.allCases, id: \.self) { type in
                    mealSection(vm: vm, type: type)
                }

                if proteinGoal > 0 {
                    suggestionsSection(vm: vm, proteinGoal: proteinGoal)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .alert("Couldn’t load", isPresented: .constant(vm.loadError != nil)) {
            Button("OK") { vm.loadError = nil }
        } message: {
            Text(vm.loadError ?? "")
        }
        .sheet(item: $suggestionTapped) { scored in
            if let uid = env.auth.currentUid {
                LogRecipeSheet(
                    uid: uid,
                    day: day,
                    recipe: scored.recipe,
                    initialServings: scored.servings
                )
                .environment(env)
            }
        }
    }

    private func remainingSummary(vm: DayDashboardViewModel, proteinGoal: Double, calorieGoal: Double) -> some View {
        let remainingP = max(proteinGoal - vm.consumed.proteinG, 0)
        let remainingC = max(calorieGoal - vm.consumed.kcal, 0)
        return HStack(spacing: Theme.Spacing.m) {
            statPill(title: "Protein left", value: "\(Int(remainingP)) g", color: Theme.Colors.protein)
            statPill(title: "Calories left", value: "\(Int(remainingC))", color: Theme.Colors.kcal)
        }
    }

    private func statPill(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3.bold()).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.m)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
    }

    @ViewBuilder
    private func mealSection(vm: DayDashboardViewModel, type: MealType) -> some View {
        let logs = vm.mealsOfType(type)
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack {
                Text(type.rawValue.capitalized).font(.headline)
                Spacer()
                if !logs.isEmpty {
                    let m = logs.reduce(Macros.zero) { $0 + $1.computedMacros }
                    Text("\(Int(m.proteinG))g P · \(Int(m.kcal)) kcal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if logs.isEmpty {
                Text("Nothing logged")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 4)
            } else {
                ForEach(logs) { log in
                    mealRow(log)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task { await vm.delete(log) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .padding(Theme.Spacing.m)
        .background(Color.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
    }

    private func mealRow(_ log: MealLog) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title(log)).font(.subheadline)
                Text(subtitle(log)).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(log.computedMacros.proteinG))g P").font(.caption.bold()).foregroundStyle(Theme.Colors.protein)
                Text("\(Int(log.computedMacros.kcal)) kcal").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private func title(_ log: MealLog) -> String {
        if let title = log.recipeTitleSnapshot { return title }
        if let adHoc = log.adHoc { return adHoc.name }
        return "Meal"
    }

    private func subtitle(_ log: MealLog) -> String {
        if let servings = log.servings {
            return "\(formatted(servings)) serving\(servings == 1 ? "" : "s")"
        }
        if let adHoc = log.adHoc {
            return "\(Int(adHoc.quantityG)) g"
        }
        return ""
    }

    private func formatted(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(v))" : String(format: "%.1f", v)
    }

    @ViewBuilder
    private func suggestionsSection(vm: DayDashboardViewModel, proteinGoal: Double) -> some View {
        let suggestions = vm.suggestions(proteinGoalG: proteinGoal)
        if !suggestions.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text("Suggestions")
                    .font(.headline)
                Text("Tap to log. Picks aim at your remaining protein target.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(suggestions, id: \.recipe.id) { scored in
                    suggestionRow(scored, day: vm.day)
                }
            }
            .padding(.top, Theme.Spacing.s)
        }
    }

    private func suggestionRow(_ scored: RecipeSuggestion.Scored, day: Date) -> some View {
        Button {
            suggestionTapped = scored
        } label: {
            HStack(spacing: Theme.Spacing.m) {
                RoundedRectangle(cornerRadius: Theme.Radius.s)
                    .fill(Theme.Colors.protein.opacity(0.15))
                    .frame(width: 40, height: 40)
                    .overlay(Image(systemName: "flame.fill").foregroundStyle(Theme.Colors.protein))
                VStack(alignment: .leading, spacing: 2) {
                    Text(scored.recipe.title).font(.subheadline).foregroundStyle(.primary)
                    Text("\(formatted(scored.servings)) serving\(scored.servings == 1 ? "" : "s") · \(Int(scored.protein))g P")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}

extension RecipeSuggestion.Scored: Identifiable {
    var id: String { recipe.id }
}
