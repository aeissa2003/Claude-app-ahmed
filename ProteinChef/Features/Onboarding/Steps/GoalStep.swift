import SwiftUI

struct GoalStep: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        Form {
            Section("What's your goal?") {
                goalRow(.cut,      label: "Cut",       blurb: "Lose fat while preserving muscle. Higher protein, slight calorie deficit.")
                goalRow(.maintain, label: "Maintain",  blurb: "Keep current bodyweight. Balanced macros, calories at maintenance.")
                goalRow(.bulk,     label: "Bulk",      blurb: "Build muscle. Slight calorie surplus, still solid protein.")
            }
        }
    }

    @ViewBuilder
    private func goalRow(_ goal: FitnessGoal, label: String, blurb: String) -> some View {
        Button {
            viewModel.goal = goal
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(label).font(.headline)
                    Text(blurb).font(.footnote).foregroundStyle(.secondary)
                }
                Spacer()
                if viewModel.goal == goal {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.Colors.protein)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
