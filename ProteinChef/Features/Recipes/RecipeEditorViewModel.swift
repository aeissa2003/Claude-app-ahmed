import Foundation
import Observation
import UIKit

@Observable
final class RecipeEditorViewModel {
    let uid: String
    let editing: Recipe?

    // Editable fields
    var title: String
    var prepMinutes: Int
    var cookMinutes: Int
    var servings: Double
    var tags: [String]
    var tagInput: String = ""
    var instructions: [RecipeStep]
    var ingredients: [RecipeIngredient]

    // Local UIImages pending upload on save.
    // Key for cover/gallery: "cover", "gallery-\(index)".
    // Key for ingredient photos: ingredient entry id.
    var pendingImages: [String: UIImage] = [:]

    // Already-uploaded URLs (used when editing).
    var coverPhotoURL: URL?
    var galleryPhotoURLs: [URL]

    var isSaving = false
    var errorText: String?

    init(uid: String, editing: Recipe? = nil) {
        self.uid = uid
        self.editing = editing
        if let r = editing {
            self.title = r.title
            self.prepMinutes = r.prepMinutes
            self.cookMinutes = r.cookMinutes
            self.servings = r.servings
            self.tags = r.tags
            self.instructions = r.instructions
            self.ingredients = r.ingredients
            self.coverPhotoURL = r.coverPhotoURL
            self.galleryPhotoURLs = r.galleryPhotoURLs
        } else {
            self.title = ""
            self.prepMinutes = 10
            self.cookMinutes = 20
            self.servings = 2
            self.tags = []
            self.instructions = []
            self.ingredients = []
            self.coverPhotoURL = nil
            self.galleryPhotoURLs = []
        }
    }

    var totalMacros: Macros {
        MacroMath.total(of: ingredients)
    }

    var perServing: Macros {
        MacroMath.perServing(total: totalMacros, servings: servings)
    }

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        servings > 0 &&
        !ingredients.isEmpty
    }

    func addTag() {
        let t = tagInput.trimmingCharacters(in: .whitespaces).lowercased()
        guard !t.isEmpty, !tags.contains(t) else { tagInput = ""; return }
        tags.append(t)
        tagInput = ""
    }

    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }

    func addInstruction() {
        instructions.append(RecipeStep(id: UUID().uuidString, order: instructions.count, text: ""))
    }

    func removeInstruction(at offsets: IndexSet) {
        instructions.remove(atOffsets: offsets)
        for (i, _) in instructions.enumerated() {
            instructions[i].order = i
        }
    }

    func addIngredient(_ ingredient: RecipeIngredient) {
        ingredients.append(ingredient)
    }

    func updateIngredient(_ ingredient: RecipeIngredient) {
        guard let idx = ingredients.firstIndex(where: { $0.id == ingredient.id }) else { return }
        ingredients[idx] = ingredient
    }

    func removeIngredient(at offsets: IndexSet) {
        let removed = offsets.map { ingredients[$0].id }
        ingredients.remove(atOffsets: offsets)
        for id in removed { pendingImages.removeValue(forKey: id) }
    }

    func setCoverImage(_ image: UIImage) {
        pendingImages["cover"] = image
    }

    func addGalleryImage(_ image: UIImage) {
        let nextIndex = galleryPhotoURLs.count + pendingImages.keys.filter { $0.hasPrefix("gallery-") }.count
        pendingImages["gallery-\(nextIndex)"] = image
    }

    func setIngredientImage(_ image: UIImage, for ingredientId: String) {
        pendingImages[ingredientId] = image
    }

    /// Builds the final Recipe snapshot (macros recomputed, isHighProtein flag set).
    func snapshot() -> Recipe {
        let now = Date()
        let total = totalMacros
        let perS  = MacroMath.perServing(total: total, servings: servings)
        return Recipe(
            id: editing?.id ?? UUID().uuidString,
            ownerUid: uid,
            title: title.trimmingCharacters(in: .whitespaces),
            coverPhotoURL: coverPhotoURL,
            galleryPhotoURLs: galleryPhotoURLs,
            instructions: instructions.filter { !$0.text.isEmpty },
            prepMinutes: prepMinutes,
            cookMinutes: cookMinutes,
            servings: servings,
            tags: tags,
            ingredients: ingredients,
            macrosTotal: total,
            macrosPerServing: perS,
            isHighProtein: MacroMath.isHighProtein(perServing: perS),
            privacy: editing?.privacy ?? .private,
            sourceRecipeId: editing?.sourceRecipeId,
            sourceUserId: editing?.sourceUserId,
            sourceUserHandle: editing?.sourceUserHandle,
            createdAt: editing?.createdAt ?? now,
            updatedAt: now
        )
    }
}
