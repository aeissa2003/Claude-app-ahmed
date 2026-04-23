import SwiftUI

struct LogAdHocSheet: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    let uid: String
    let day: Date
    var initialMealType: MealType? = nil
    var onLogged: (() -> Void)?

    @State private var mealType: MealType?
    @State private var mode: Mode = .search

    // Search mode state
    @State private var query: String = ""
    @State private var selected: Ingredient?
    @State private var quantityG: Double = 100

    // Manual mode state
    @State private var manualName: String = ""
    @State private var manualProtein: Double = 0
    @State private var manualCarbs: Double = 0
    @State private var manualFat: Double = 0
    @State private var manualKcal: Double = 0

    @State private var isSaving = false
    @State private var errorText: String?

    enum Mode: Hashable {
        case search
        case manual
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Entry style", selection: $mode) {
                    Text("Search catalog").tag(Mode.search)
                    Text("Manual entry").tag(Mode.manual)
                }
                .pickerStyle(.segmented)

                switch mode {
                case .search: searchSection
                case .manual: manualSection
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
                    macroSummary(previewMacros)
                }
            }
            .navigationTitle("Quick add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") {
                        Task { await save() }
                    }
                    .disabled(!canSave || isSaving)
                }
            }
            .alert("Couldn’t log meal", isPresented: .constant(errorText != nil)) {
                Button("OK") { errorText = nil }
            } message: {
                Text(errorText ?? "")
            }
            .onAppear { if mealType == nil { mealType = initialMealType } }
        }
    }

    // MARK: - Sections

    @ViewBuilder private var searchSection: some View {
        Section("Ingredient") {
            TextField("Search", text: $query)
                .textInputAutocapitalization(.never)
            ForEach(env.ingredientCatalog.search(query, limit: 8)) { ing in
                Button {
                    selected = ing
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ing.name).foregroundStyle(.primary)
                            Text("\(Int(ing.macrosPer100g.proteinG))g P · \(Int(ing.macrosPer100g.kcal)) kcal / 100g")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if selected?.id == ing.id {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.Colors.protein)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            if selected != nil {
                HStack {
                    Text("Quantity")
                    Spacer()
                    TextField("g", value: $quantityG, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 80)
                    Text("g").foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder private var manualSection: some View {
        Section("Food") {
            TextField("Name", text: $manualName)
            HStack {
                Text("Portion")
                Spacer()
                TextField("g", value: $quantityG, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 80)
                Text("g").foregroundStyle(.secondary)
            }
        }
        Section("Macros (for this portion)") {
            macroField("Protein", value: $manualProtein, unit: "g")
            macroField("Carbs", value: $manualCarbs, unit: "g")
            macroField("Fat", value: $manualFat, unit: "g")
            macroField("Calories", value: $manualKcal, unit: "kcal")
        }
    }

    private func macroField(_ label: String, value: Binding<Double>, unit: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField(unit, value: value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 80)
            Text(unit).foregroundStyle(.secondary)
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

    // MARK: - Computed

    private var previewMacros: Macros {
        switch mode {
        case .search:
            guard let selected else { return .zero }
            return MacroMath.macros(forGrams: quantityG, per100g: selected.macrosPer100g)
        case .manual:
            return Macros(
                proteinG: manualProtein,
                carbsG: manualCarbs,
                fatG: manualFat,
                kcal: manualKcal
            )
        }
    }

    private var canSave: Bool {
        guard mealType != nil else { return false }
        switch mode {
        case .search:
            return selected != nil && quantityG > 0
        case .manual:
            return !manualName.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    // MARK: - Save

    private func save() async {
        guard let mealType else { return }
        isSaving = true
        defer { isSaving = false }

        let adHoc: AdHocFood
        switch mode {
        case .search:
            guard let selected else { return }
            adHoc = AdHocFood(
                name: selected.name,
                matchedIngredientId: selected.id,
                quantityG: quantityG,
                macros: previewMacros
            )
        case .manual:
            adHoc = AdHocFood(
                name: manualName.trimmingCharacters(in: .whitespaces),
                matchedIngredientId: nil,
                quantityG: quantityG,
                macros: previewMacros
            )
        }

        let log = MealLog(
            id: UUID().uuidString,
            ownerUid: uid,
            date: MealLogDate.normalizeToNoon(day),
            mealType: mealType,
            recipeId: nil,
            recipeTitleSnapshot: nil,
            servings: nil,
            adHoc: adHoc,
            computedMacros: adHoc.macros,
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
