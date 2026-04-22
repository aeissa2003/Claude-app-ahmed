import SwiftUI

struct IngredientPickerView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    @State private var vm: IngredientPickerViewModel?
    private let editing: RecipeIngredient?
    let onConfirm: (RecipeIngredient) -> Void

    init(editing: RecipeIngredient? = nil, onConfirm: @escaping (RecipeIngredient) -> Void) {
        self.editing = editing
        self.onConfirm = onConfirm
    }

    var body: some View {
        NavigationStack {
            Group {
                if let vm {
                    content(vm: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(editing == nil ? "Add ingredient" : "Edit ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editing == nil ? "Add" : "Update") {
                        confirm()
                    }
                    .disabled(!(vm?.isSelectionReady ?? false))
                }
            }
        }
        .task {
            if vm == nil {
                let viewModel = IngredientPickerViewModel(
                    catalog: env.ingredientCatalog,
                    customRepo: env.customIngredients,
                    uid: env.auth.currentUid ?? "",
                    editing: editing
                )
                vm = viewModel
                await viewModel.loadCustom()
            }
        }
    }

    @ViewBuilder
    private func content(vm: IngredientPickerViewModel) -> some View {
        @Bindable var vm = vm
        Form {
            Section {
                TextField("Search", text: $vm.query)
                    .textInputAutocapitalization(.never)
                    .onChange(of: vm.query) { _, _ in vm.refreshCatalog() }
            }

            if let name = vm.selectedIngredientName {
                Section("Selected") {
                    Text(name).font(.headline)
                    quantityEditor(vm: vm)
                    macrosPreview(vm: vm)
                }
            }

            if !vm.customResults.isEmpty {
                Section("Your custom ingredients") {
                    ForEach(vm.customResults) { custom in
                        Button {
                            vm.selectCustom(custom)
                        } label: {
                            ingredientLabel(
                                name: custom.name,
                                detail: "Custom · \(Int(custom.macrosPer100g.proteinG))g P / 100g",
                                selected: vm.selectedCustomId == custom.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section("Catalog") {
                if vm.results.isEmpty && !vm.query.isEmpty {
                    Button {
                        vm.prepareCustomForm()
                    } label: {
                        Label("Add “\(vm.query)” as custom ingredient", systemImage: "plus.circle")
                    }
                } else {
                    ForEach(vm.results) { ing in
                        Button {
                            vm.select(ing)
                        } label: {
                            ingredientLabel(
                                name: ing.name,
                                detail: "\(Int(ing.macrosPer100g.proteinG))g P · \(Int(ing.macrosPer100g.kcal)) kcal / 100g",
                                selected: vm.selectedIngredientId == ing.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .sheet(isPresented: $vm.showingCustomForm) {
            CustomIngredientForm(vm: vm)
        }
        .alert("Error", isPresented: .constant(vm.errorText != nil)) {
            Button("OK") { vm.errorText = nil }
        } message: {
            Text(vm.errorText ?? "")
        }
    }

    @ViewBuilder
    private func quantityEditor(vm: IngredientPickerViewModel) -> some View {
        @Bindable var vm = vm
        HStack {
            TextField("Quantity", value: $vm.displayQuantity, format: .number)
                .keyboardType(.decimalPad)
                .frame(maxWidth: 100)
            Picker("Unit", selection: $vm.displayUnit) {
                ForEach(vm.availableUnits, id: \.self) { u in
                    Text(u).tag(u)
                }
            }
            .pickerStyle(.menu)
            Spacer()
            Text(gramsReadout(vm: vm)).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func gramsReadout(vm: IngredientPickerViewModel) -> String {
        let g = vm.quantityInGrams
        return g.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(g)) g"
            : String(format: "%.1f g", g)
    }

    private func macrosPreview(vm: IngredientPickerViewModel) -> some View {
        let m = vm.projectedMacros
        return HStack(spacing: Theme.Spacing.m) {
            macroChip("P", "\(Int(m.proteinG))", Theme.Colors.protein)
            macroChip("C", "\(Int(m.carbsG))", Theme.Colors.carbs)
            macroChip("F", "\(Int(m.fatG))", Theme.Colors.fat)
            macroChip("kcal", "\(Int(m.kcal))", Theme.Colors.kcal)
        }
    }

    private func macroChip(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.footnote.bold()).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.s))
    }

    private func ingredientLabel(name: String, detail: String, selected: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name).foregroundStyle(.primary)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if selected {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.Colors.protein)
            }
        }
    }

    private func confirm() {
        guard let vm, let entry = vm.buildRecipeIngredient() else { return }
        onConfirm(entry)
        dismiss()
    }
}

// MARK: - Custom ingredient form

private struct CustomIngredientForm: View {
    @Bindable var vm: IngredientPickerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Ingredient") {
                    TextField("Name", text: $vm.customName)
                    Picker("Category", selection: $vm.customCategory) {
                        ForEach(IngredientCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue.capitalized).tag(cat)
                        }
                    }
                }
                Section("Macros per 100g") {
                    HStack {
                        Text("Protein")
                        Spacer()
                        TextField("g", value: $vm.customProteinPer100g, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 80)
                    }
                    HStack {
                        Text("Carbs")
                        Spacer()
                        TextField("g", value: $vm.customCarbsPer100g, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 80)
                    }
                    HStack {
                        Text("Fat")
                        Spacer()
                        TextField("g", value: $vm.customFatPer100g, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 80)
                    }
                    HStack {
                        Text("Calories")
                        Spacer()
                        TextField("kcal", value: $vm.customKcalPer100g, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 80)
                    }
                }
            }
            .navigationTitle("New ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await vm.saveAndSelectCustom()
                            if !vm.showingCustomForm { dismiss() }
                        }
                    }
                    .disabled(vm.customName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
