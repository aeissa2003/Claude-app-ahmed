import XCTest
@testable import ProteinChef

final class MacroMathTests: XCTestCase {
    func testMacrosForGramsScales() {
        let per100 = Macros(proteinG: 31, carbsG: 0, fatG: 3.6, kcal: 165)
        let result = MacroMath.macros(forGrams: 250, per100g: per100)
        XCTAssertEqual(result.proteinG, 77.5, accuracy: 0.001)
        XCTAssertEqual(result.kcal, 412.5, accuracy: 0.001)
    }

    func testRecipeTotalSumsIngredients() {
        let ing: (Double, Macros) -> RecipeIngredient = { grams, macros in
            RecipeIngredient(
                id: UUID().uuidString,
                ingredientId: "x",
                ingredientName: "x",
                isCustom: false,
                quantityG: grams,
                displayQuantity: grams,
                displayUnit: "g",
                photoURL: nil,
                macrosAtEntry: macros * (grams / 100)
            )
        }
        let chicken = Macros(proteinG: 31, carbsG: 0, fatG: 3.6, kcal: 165)
        let rice = Macros(proteinG: 2.7, carbsG: 28, fatG: 0.3, kcal: 130)
        let ingredients = [ing(200, chicken), ing(300, rice)]
        let total = MacroMath.total(of: ingredients)
        XCTAssertEqual(total.proteinG, 62 + 8.1, accuracy: 0.01)
    }

    func testHighProteinThreshold() {
        let lowProtein = Macros(proteinG: 15, carbsG: 40, fatG: 10, kcal: 300)
        let highProtein = Macros(proteinG: 35, carbsG: 20, fatG: 10, kcal: 310)
        XCTAssertFalse(MacroMath.isHighProtein(perServing: lowProtein))
        XCTAssertTrue(MacroMath.isHighProtein(perServing: highProtein))
    }

    func testProteinGoalRoundsToFive() {
        XCTAssertEqual(MacroMath.recommendedProteinGoal(bodyweightKg: 80, goal: .cut), 175)
        XCTAssertEqual(MacroMath.recommendedProteinGoal(bodyweightKg: 80, goal: .maintain), 145)
        XCTAssertEqual(MacroMath.recommendedProteinGoal(bodyweightKg: 80, goal: .bulk), 130)
    }
}
