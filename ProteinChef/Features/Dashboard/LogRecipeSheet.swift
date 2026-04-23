import SwiftUI

/// Step 2 of recipe logging: pick meal type and servings, confirm macros, save.
/// Also used directly when the user taps a dashboard "Suggestion".
struct LogRecipeSheet: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    let uid: String
    let day: Date
    let recipe: Recipe
    let initialServings: Double
    var onLogged: (() -> Void)?

    @State private var servings: Double
    @State private var mealType: MealType?
    @State private var isSaving: Bool = false
    @State private var errorText: String?

    init(
        uid: String,
        day: Date,
        recipe: Recipe,
        initialServings: Double = 1,
        onLogged: (() -> Void)? = nil
    ) {
        self.uid = uid
        self.day = day
        self.recipe = recipe
        self.initialServings = initialServings
        self.onLogged = onLogged
        _servings = State(initialValue: initialServings)
    }

    private var computedMacros: Macros {
        recipe.macrosPerServing * servings
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(recipe.title) {
                    HStack {
                        Text("Servings")
                        Spacer()
                        Stepper(value: $servings, in: 0.5...10, step: 0.5) {
                            Text(formatted(servings)).monospacedDigit()
                        }
                        .labelsHidden()
                    }
                }

                Section("Meal") {
                    Picker("Meal type", selection: $mealType) {
                        Text("Select…").tag(Optional<MealType>.none)
                        ForEach(MealType.allCases, id: \.self) { t in
                            Text(t.rawValue.capitalized).tag(Optional(t))
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("This will add") {
                    macroSummary(computedMacros)
                }
            }
            .navigationTitle("Log recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") {
                        Task { await save() }
                    }
                    .disabled(mealType == nil || servings <= 0 || isSaving)
                }
            }
            .overlay { if isSaving { ProgressView().padding(20).background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m)) } }
            .alert("Couldn’t log meal", isPresented: .constant(errorText != nil)) {
                Button("OK") { errorText = nil }
            } message: {
                Text(errorText ?? "")
            }
        }
    }

    private func macroSummary(_ m: Macros) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            labeledValue("Protein", "\(Int(m.proteinG))g", Theme.Colors.protein)
            labeledValue("Carbs", "\(Int(m.carbsG))g", Theme.Colors.carbs)
            labeledValue("Fat", "\(Int(m.fatG))g", Theme.Colors.fat)
            labeledValue("Kcal", "\(Int(m.kcal))", Theme.Colors.kcal)
        }
        .padding(.vertical, 4)
    }

    private func labeledValue(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.subheadline.bold()).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.s))
    }

    private func formatted(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(v))" : String(format: "%.1f", v)
    }

    private func save() async {
        guard let mealType else { return }
        isSaving = true
        defer { isSaving = false }
        let log = MealLog(
            id: UUID().uuidString,
            ownerUid: uid,
            date: MealLogDate.normalizeToNoon(day),
            mealType: mealType,
            recipeId: recipe.id,
            recipeTitleSnapshot: recipe.title,
            servings: servings,
            adHoc: nil,
            computedMacros: computedMacros,
            createdAt: Date()
        )
        do {
            try await env.mealLogs.save(log)
            onLogged?()
            dismiss()
        } catch {
            errorText = error.localizedDescription
        }
    }
}
