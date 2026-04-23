import SwiftUI

/// A labeled circular progress ring representing consumed-vs-goal for a single macro.
struct MacroRing: View {
    let label: String
    let current: Double
    let goal: Double
    let unit: String
    let color: Color
    var lineWidth: CGFloat = 10
    var size: CGFloat = 72

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(current / goal, 1)
    }

    private var overflow: Double {
        guard goal > 0 else { return 0 }
        return max((current / goal) - 1, 0)
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: lineWidth)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                if overflow > 0 {
                    Circle()
                        .trim(from: 0, to: min(overflow, 1))
                        .stroke(color.opacity(0.5), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .scaleEffect(0.78)
                }
                VStack(spacing: 0) {
                    Text("\(Int(current))")
                        .font(.system(size: size * 0.28, weight: .bold))
                        .foregroundStyle(color)
                    Text(unit)
                        .font(.system(size: size * 0.14))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: size, height: size)

            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(goal > 0 ? "of \(Int(goal))" : "—")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}

/// Row of four MacroRings for protein, carbs, fat, calories.
struct MacroRingsRow: View {
    let consumed: Macros
    let proteinGoalG: Double
    let calorieGoalKcal: Double
    let carbsGoalG: Double?
    let fatGoalG: Double?

    var body: some View {
        HStack(spacing: Theme.Spacing.s) {
            MacroRing(
                label: "Protein",
                current: consumed.proteinG,
                goal: proteinGoalG,
                unit: "g",
                color: Theme.Colors.protein
            )
            MacroRing(
                label: "Carbs",
                current: consumed.carbsG,
                goal: carbsGoalG ?? 0,
                unit: "g",
                color: Theme.Colors.carbs
            )
            MacroRing(
                label: "Fat",
                current: consumed.fatG,
                goal: fatGoalG ?? 0,
                unit: "g",
                color: Theme.Colors.fat
            )
            MacroRing(
                label: "Calories",
                current: consumed.kcal,
                goal: calorieGoalKcal,
                unit: "kcal",
                color: Theme.Colors.kcal
            )
        }
        .frame(maxWidth: .infinity)
    }
}
