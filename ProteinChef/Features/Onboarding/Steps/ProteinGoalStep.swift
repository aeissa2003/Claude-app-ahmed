import SwiftUI

struct ProteinGoalStep: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    Text("Daily protein target")
                        .font(.headline)
                    Text("\(Int(viewModel.proteinGoalG)) g / day")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.Colors.protein)
                    Slider(
                        value: $viewModel.proteinGoalG,
                        in: 40...300,
                        step: 5
                    )
                    HStack {
                        Text("40 g").font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Text("300 g").font(.caption).foregroundStyle(.secondary)
                    }
                }
            } footer: {
                Text("Suggested: \(Int(viewModel.computedProteinGoal)) g based on \(Int(viewModel.weightKg)) kg bodyweight and your goal. Slide to adjust.")
            }

            Section("Calories (starter target)") {
                HStack {
                    Text("Daily calories")
                    Spacer()
                    Text("\(Int(viewModel.computedCalorieGoal)) kcal").foregroundStyle(.secondary)
                }
            } footer: {
                Text("A rough starting point from Mifflin–St Jeor + activity estimate. You can adjust this in Settings once we have a few days of logs.")
            }
        }
    }
}
