import Foundation

struct Macros: Codable, Hashable, Sendable {
    var proteinG: Double
    var carbsG: Double
    var fatG: Double
    var kcal: Double

    static let zero = Macros(proteinG: 0, carbsG: 0, fatG: 0, kcal: 0)

    static func + (lhs: Macros, rhs: Macros) -> Macros {
        Macros(
            proteinG: lhs.proteinG + rhs.proteinG,
            carbsG: lhs.carbsG + rhs.carbsG,
            fatG: lhs.fatG + rhs.fatG,
            kcal: lhs.kcal + rhs.kcal
        )
    }

    static func * (lhs: Macros, scalar: Double) -> Macros {
        Macros(
            proteinG: lhs.proteinG * scalar,
            carbsG: lhs.carbsG * scalar,
            fatG: lhs.fatG * scalar,
            kcal: lhs.kcal * scalar
        )
    }
}
