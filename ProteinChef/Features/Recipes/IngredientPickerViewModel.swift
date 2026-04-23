import Foundation
import Observation
import UIKit

/// Result delivered back to the RecipeEditor when the user picks & confirms an ingredient.
/// Holds a RecipeIngredient plus an optional local UIImage so the editor can keep it in
/// `pendingImages` until the recipe is saved.
struct PickedIngredient {
    let ingredient: RecipeIngredient
    let image: UIImage?
}

@Observable
final class IngredientPickerViewModel {
    // Search / selection
    var query: String = ""
    var results: [Ingredient] = []
    var customResults: [CustomIngredient] = []
    var selectedIngredientId: String?
    var selectedCustomId: String?
    var selectedIngredientName: String?
    var selectedMacrosPer100g: Macros?
    var selectedCommonUnits: [UnitPortion] = []

    // Quantity editing
    var displayQuantity: Double = 100
    var displayUnit: String = "g"

    // Custom ingredient creation
    var showingCustomForm: Bool = false
    var customName: String = ""
    var customCategory: IngredientCategory = .other
    var customProteinPer100g: Double = 0
    var customCarbsPer100g: Double = 0
    var customFatPer100g: Double = 0
    var customKcalPer100g: Double = 0

    // Existing ingredient entry (when editing)
    var editingEntryId: String?
    var existingPhotoURL: URL?

    // State
    var errorText: String?

    private let catalog: IngredientCatalogProtocol
    private let customRepo: CustomIngredientRepositoryProtocol
    private let uid: String

    init(
        catalog: IngredientCatalogProtocol,
        customRepo: CustomIngredientRepositoryProtocol,
        uid: String,
        editing: RecipeIngredient? = nil
    ) {
        self.catalog = catalog
        self.customRepo = customRepo
        self.uid = uid

        if let entry = editing {
            self.editingEntryId = entry.id
            self.selectedIngredientName = entry.ingredientName
            self.displayQuantity = entry.displayQuantity
            self.displayUnit = entry.displayUnit
            self.existingPhotoURL = entry.photoURL
            if entry.isCustom {
                self.selectedCustomId = entry.ingredientId
            } else {
                self.selectedIngredientId = entry.ingredientId
                if let ing = catalog.ingredient(id: entry.ingredientId) {
                    self.selectedMacrosPer100g = ing.macrosPer100g
                    self.selectedCommonUnits = ing.commonUnits ?? []
                }
            }
            // Cheap fallback for custom: use the snapshot back-calculated.
            if entry.isCustom, entry.quantityG > 0 {
                self.selectedMacrosPer100g = entry.macrosAtEntry * (100.0 / entry.quantityG)
            }
        }

        refreshCatalog()
    }

    var isSelectionReady: Bool {
        (selectedIngredientId != nil || selectedCustomId != nil) &&
        selectedMacrosPer100g != nil &&
        displayQuantity > 0
    }

    /// Grams represented by the user's current quantity+unit choice.
    var quantityInGrams: Double {
        switch displayUnit.lowercased() {
        case "g", "gram", "grams":
            return displayQuantity
        case "kg":
            return displayQuantity * 1000
        case "oz":
            return UnitConversion.grams(fromOz: displayQuantity)
        case "lb":
            return UnitConversion.grams(fromOz: displayQuantity * 16)
        default:
            if let portion = selectedCommonUnits.first(where: { $0.label == displayUnit }) {
                return displayQuantity * portion.grams
            }
            return displayQuantity
        }
    }

    var projectedMacros: Macros {
        guard let per100 = selectedMacrosPer100g else { return .zero }
        return MacroMath.macros(forGrams: quantityInGrams, per100g: per100)
    }

    var availableUnits: [String] {
        var units = ["g", "kg", "oz", "lb"]
        units.append(contentsOf: selectedCommonUnits.map(\.label))
        return units
    }

    // MARK: - Actions

    func refreshCatalog() {
        results = catalog.search(query, limit: 40)
    }

    func loadCustom() async {
        do {
            customResults = try await customRepo.list(ownerUid: uid)
        } catch {
            customResults = []
        }
    }

    func select(_ ingredient: Ingredient) {
        selectedCustomId = nil
        selectedIngredientId = ingredient.id
        selectedIngredientName = ingredient.name
        selectedMacrosPer100g = ingredient.macrosPer100g
        selectedCommonUnits = ingredient.commonUnits ?? []
        if editingEntryId == nil {
            displayQuantity = 100
            displayUnit = "g"
        }
    }

    func selectCustom(_ ingredient: CustomIngredient) {
        selectedIngredientId = nil
        selectedCustomId = ingredient.id
        selectedIngredientName = ingredient.name
        selectedMacrosPer100g = ingredient.macrosPer100g
        selectedCommonUnits = []
        if editingEntryId == nil {
            displayQuantity = 100
            displayUnit = "g"
        }
    }

    func prepareCustomForm() {
        showingCustomForm = true
        customName = query
        customCategory = .other
        customProteinPer100g = 0
        customCarbsPer100g = 0
        customFatPer100g = 0
        customKcalPer100g = 0
    }

    /// Saves the user-created custom ingredient to Firestore, then selects it.
    func saveAndSelectCustom() async {
        let trimmed = customName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            errorText = "Ingredient name required."
            return
        }
        let ing = CustomIngredient(
            id: UUID().uuidString,
            name: trimmed,
            category: customCategory,
            macrosPer100g: Macros(
                proteinG: customProteinPer100g,
                carbsG: customCarbsPer100g,
                fatG: customFatPer100g,
                kcal: customKcalPer100g
            ),
            createdAt: Date()
        )
        do {
            try await customRepo.save(ownerUid: uid, ing)
            customResults.append(ing)
            selectCustom(ing)
            showingCustomForm = false
        } catch {
            errorText = error.localizedDescription
        }
    }

    /// Builds the final RecipeIngredient to hand back to the editor.
    func buildRecipeIngredient() -> RecipeIngredient? {
        guard let per100 = selectedMacrosPer100g,
              let name = selectedIngredientName,
              let sourceId = selectedIngredientId ?? selectedCustomId else { return nil }
        let grams = quantityInGrams
        return RecipeIngredient(
            id: editingEntryId ?? UUID().uuidString,
            ingredientId: sourceId,
            ingredientName: name,
            isCustom: selectedCustomId != nil,
            quantityG: grams,
            displayQuantity: displayQuantity,
            displayUnit: displayUnit,
            photoURL: existingPhotoURL,
            macrosAtEntry: MacroMath.macros(forGrams: grams, per100g: per100)
        )
    }
}
