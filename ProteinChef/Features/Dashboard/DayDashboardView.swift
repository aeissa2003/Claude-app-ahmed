import SwiftUI

struct DayDashboardView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.userProfile) private var profile
    let day: Date

    @State private var vm: DayDashboardViewModel?
    @State private var suggestionTapped: RecipeSuggestion.Scored?
    @State private var mealTypeToLog: MealType?

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

    // MARK: - Content

    @ViewBuilder
    private func content(vm: DayDashboardViewModel) -> some View {
        let proteinGoal = profile?.proteinGoalG ?? 0
        let calorieGoal = profile?.calorieGoalKcal ?? 0
        let consumed    = vm.consumed

        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                heroCard(consumed: consumed, goal: proteinGoal)
                secondaryMacrosCard(consumed: consumed, calorieGoal: calorieGoal)
                mealsSection(vm: vm)
                if proteinGoal > 0 {
                    suggestionsSection(vm: vm, proteinGoal: proteinGoal)
                }
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.bottom, 140) // room for the tab bar
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
        .sheet(item: $mealTypeToLog) { type in
            if let uid = env.auth.currentUid {
                LogMealSheet(uid: uid, day: day, initialMealType: type)
                    .environment(env)
            }
        }
    }

    // MARK: - Hero card

    private func heroCard(consumed: Macros, goal: Double) -> some View {
        let remaining = max(goal - consumed.proteinG, 0)
        let pct = goal > 0 ? Int(min(100, (consumed.proteinG / goal) * 100)) : 0
        let onPace = pct >= paceTargetForNow()

        return PCCard(style: .ink, padding: 20) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    PCEyebrow(text: "Protein left", color: Theme.Colors.ink4)
                    Spacer()
                    Text(onPace ? "ON PACE" : "BEHIND")
                        .font(Theme.Fonts.mono(9, weight: .semibold))
                        .tracking(1.0)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Theme.Colors.lime)
                        .foregroundStyle(Theme.Colors.limeInk)
                        .clipShape(Capsule())
                }
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(Int(remaining))")
                        .font(Theme.Fonts.display(80))
                        .tracking(-2.5)
                        .foregroundStyle(Theme.Colors.lime)
                    Text("g")
                        .font(Theme.Fonts.display(22))
                        .foregroundStyle(Color.white.opacity(0.7))
                        .padding(.bottom, 16)
                }
                Text("\(Int(consumed.proteinG)) of \(Int(goal))g logged · \(pct)%")
                    .font(Theme.Fonts.ui(13))
                    .foregroundStyle(Color.white.opacity(0.65))

                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1))
                        .frame(height: 10)
                    GeometryReader { geo in
                        Capsule()
                            .fill(Theme.Colors.lime)
                            .frame(width: min(1, consumed.proteinG / max(goal, 1)) * geo.size.width,
                                   height: 10)
                            .animation(.easeOut(duration: 0.6), value: consumed.proteinG)
                    }
                    .frame(height: 10)
                }

                HStack {
                    Text("0")
                        .font(Theme.Fonts.mono(10))
                        .foregroundStyle(Color.white.opacity(0.55))
                    Spacer()
                    Text("\(Int(goal))g GOAL")
                        .font(Theme.Fonts.mono(10))
                        .tracking(0.8)
                        .foregroundStyle(Color.white.opacity(0.55))
                }
            }
        }
    }

    private func paceTargetForNow() -> Int {
        // Expect linear progress across the day: at noon, 50%.
        let h = Calendar.current.component(.hour, from: Date())
        return min(95, max(5, h * 100 / 24))
    }

    // MARK: - Secondary macros card (Calories / Carbs / Fat)

    private func secondaryMacrosCard(consumed: Macros, calorieGoal: Double) -> some View {
        PCCard(style: .paper, padding: 18) {
            VStack(spacing: 16) {
                macroRow(label: "Calories",
                         current: consumed.kcal,
                         goal: calorieGoal,
                         unit: "kcal",
                         tint: Theme.Colors.kcal)
                macroRow(label: "Carbs",
                         current: consumed.carbsG,
                         goal: 260,
                         unit: "g",
                         tint: Theme.Colors.carbs)
                macroRow(label: "Fat",
                         current: consumed.fatG,
                         goal: 70,
                         unit: "g",
                         tint: Theme.Colors.fat)
            }
        }
    }

    private func macroRow(label: String,
                          current: Double,
                          goal: Double,
                          unit: String,
                          tint: Color) -> some View {
        let pct = goal > 0 ? Int(min(100, current / goal * 100)) : 0
        let remaining = max(goal - current, 0)
        return VStack(spacing: 6) {
            HStack(alignment: .lastTextBaseline) {
                PCEyebrow(text: label)
                Spacer()
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(Int(current))")
                        .font(Theme.Fonts.display(22))
                        .tracking(-0.5)
                    Text("/ \(Int(goal)) \(unit)")
                        .font(Theme.Fonts.ui(11))
                        .foregroundStyle(Theme.Colors.ink3)
                }
            }
            PCMacroBar(current: current, goal: goal, tint: tint, height: 8)
            HStack {
                Text("\(Int(remaining)) \(unit) left")
                    .font(Theme.Fonts.ui(11))
                    .foregroundStyle(Theme.Colors.ink3)
                Spacer()
                Text("\(pct)%")
                    .font(Theme.Fonts.ui(11))
                    .foregroundStyle(Theme.Colors.ink3)
            }
        }
    }

    // MARK: - Meals section

    @ViewBuilder
    private func mealsSection(vm: DayDashboardViewModel) -> some View {
        let totalLogged = vm.meals.count
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack(alignment: .lastTextBaseline) {
                Text("Meals").font(Theme.Fonts.sectionTitle).tracking(-0.5)
                Spacer()
                PCEyebrow(text: "\(totalLogged) logged")
            }
            VStack(spacing: Theme.Spacing.s) {
                ForEach(MealType.allCases, id: \.self) { type in
                    mealCard(vm: vm, type: type)
                }
            }
        }
        .padding(.top, Theme.Spacing.s)
    }

    private func mealCard(vm: DayDashboardViewModel, type: MealType) -> some View {
        let logs = vm.mealsOfType(type)
        let m = logs.reduce(Macros.zero) { $0 + $1.computedMacros }

        return PCCard(style: .paper, padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text(type.rawValue.capitalized)
                        .font(Theme.Fonts.cardTitle)
                    Spacer()
                    if logs.isEmpty {
                        PCEyebrow(text: "Empty")
                    } else {
                        Text("\(Int(m.proteinG))g · \(Int(m.kcal)) kcal")
                            .font(Theme.Fonts.mono(11))
                            .foregroundStyle(Theme.Colors.ink3)
                    }
                }

                if logs.isEmpty {
                    HStack {
                        PCChip(text: "Add", style: .neutral, systemImage: "plus") {
                            mealTypeToLog = type
                        }
                        Spacer()
                    }
                } else {
                    VStack(spacing: 0) {
                        ForEach(logs) { log in
                            mealRow(log)
                                .padding(.vertical, 10)
                                .overlay(
                                    Rectangle()
                                        .fill(Theme.Colors.line)
                                        .frame(height: 1),
                                    alignment: .bottom
                                )
                        }
                    }
                }
            }
        }
        .contextMenu {
            Button {
                mealTypeToLog = type
            } label: {
                Label("Log \(type.rawValue.lowercased())", systemImage: "plus")
            }
        }
    }

    private func mealRow(_ log: MealLog) -> some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title(log)).font(Theme.Fonts.bodyStrong)
                Text(subtitle(log)).font(Theme.Fonts.mono(11)).foregroundStyle(Theme.Colors.ink3)
            }
            Spacer()
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(Int(log.computedMacros.proteinG))")
                    .font(Theme.Fonts.display(22))
                    .foregroundStyle(Theme.Colors.protein)
                Text("g").font(Theme.Fonts.ui(11)).foregroundStyle(Theme.Colors.protein.opacity(0.8))
                Text("\(Int(log.computedMacros.kcal)) kcal")
                    .font(Theme.Fonts.mono(10))
                    .foregroundStyle(Theme.Colors.ink3)
                    .padding(.leading, 8)
            }
        }
    }

    private func title(_ log: MealLog) -> String {
        if let title = log.recipeTitleSnapshot { return title }
        if let adHoc = log.adHoc { return adHoc.name }
        return "Meal"
    }

    private func subtitle(_ log: MealLog) -> String {
        if let servings = log.servings {
            return "\(formatted(servings)) SERVING\(servings == 1 ? "" : "S")"
        }
        if let adHoc = log.adHoc {
            return "\(Int(adHoc.quantityG)) G"
        }
        return ""
    }

    private func formatted(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(v))" : String(format: "%.1f", v)
    }

    // MARK: - Suggestions

    @ViewBuilder
    private func suggestionsSection(vm: DayDashboardViewModel, proteinGoal: Double) -> some View {
        let suggestions = vm.suggestions(proteinGoalG: proteinGoal, limit: 6)
        if !suggestions.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                HStack(alignment: .lastTextBaseline) {
                    Text("Suggestions").font(Theme.Fonts.sectionTitle).tracking(-0.5)
                    Spacer()
                    PCEyebrow(text: "fit your goal")
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(suggestions, id: \.recipe.id) { scored in
                            suggestionCard(scored)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(.top, Theme.Spacing.s)
        }
    }

    private func suggestionCard(_ scored: RecipeSuggestion.Scored) -> some View {
        Button {
            suggestionTapped = scored
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .topLeading) {
                    PCCoverImage(
                        url: scored.recipe.coverPhotoURL,
                        placeholderLabel: String(scored.recipe.title.prefix(10)),
                        height: 120
                    )
                    if scored.recipe.isHighProtein {
                        Text("HP")
                            .font(Theme.Fonts.mono(9, weight: .semibold))
                            .tracking(0.8)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Theme.Colors.lime)
                            .foregroundStyle(Theme.Colors.limeInk)
                            .clipShape(Capsule())
                            .padding(10)
                    }
                }
                Text(scored.recipe.title)
                    .font(Theme.Fonts.ui(14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text("\(Int(scored.protein))g P · \(Int(scored.recipe.macrosPerServing.kcal)) kcal · \(formatted(scored.servings)) serv")
                    .font(Theme.Fonts.mono(10))
                    .foregroundStyle(Theme.Colors.ink3)
            }
            .frame(width: 180, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}

extension RecipeSuggestion.Scored: Identifiable {
    var id: String { recipe.id }
}

extension MealType: Identifiable {
    public var id: String { rawValue }
}
