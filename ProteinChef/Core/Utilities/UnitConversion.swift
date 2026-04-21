import Foundation

/// All weights/volumes are stored canonically in metric (g, kg, ml).
/// This helper converts for display and parses user input.
enum UnitConversion {
    // MARK: - Mass

    static func kg(fromLb lb: Double) -> Double { lb * 0.45359237 }
    static func lb(fromKg kg: Double) -> Double { kg / 0.45359237 }

    static func grams(fromOz oz: Double) -> Double { oz * 28.349523125 }
    static func oz(fromGrams g: Double) -> Double { g / 28.349523125 }

    // MARK: - Display

    static func formatBodyWeight(kg: Double, units: UnitsPreference) -> String {
        switch units {
        case .metric:   String(format: "%.1f kg", kg)
        case .imperial: String(format: "%.1f lb", lb(fromKg: kg))
        }
    }

    static func formatLiftWeight(kg: Double, units: UnitsPreference) -> String {
        switch units {
        case .metric:   String(format: "%.1f kg", kg)
        case .imperial: String(format: "%.1f lb", lb(fromKg: kg))
        }
    }

    static func formatIngredientMass(grams: Double, units: UnitsPreference) -> String {
        switch units {
        case .metric:
            grams >= 1000
                ? String(format: "%.2f kg", grams / 1000)
                : String(format: "%.0f g", grams)
        case .imperial:
            String(format: "%.2f oz", oz(fromGrams: grams))
        }
    }

    // MARK: - Height

    static func formatHeight(cm: Double, units: UnitsPreference) -> String {
        switch units {
        case .metric:
            String(format: "%.0f cm", cm)
        case .imperial:
            let totalInches = cm / 2.54
            let feet = Int(totalInches / 12)
            let inches = Int(totalInches.truncatingRemainder(dividingBy: 12).rounded())
            return "\(feet)′\(inches)″"
        }
    }
}
