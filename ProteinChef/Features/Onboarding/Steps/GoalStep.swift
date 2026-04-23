import SwiftUI

struct GoalStep: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("STEP 4 OF 6")
                    .font(Theme.Fonts.mono(10, weight: .semibold))
                    .tracking(1.0)
                    .foregroundStyle(Theme.Colors.indigo)

                Text("What are\nyou training\nfor?")
                    .font(Theme.Fonts.display(34))
                    .tracking(-1.0)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Shapes your calorie and protein targets. Switchable anytime from Settings.")
                    .font(Theme.Fonts.ui(14))
                    .foregroundStyle(Theme.Colors.ink3)

                VStack(spacing: 12) {
                    goalCard(.cut,      title: "Cut",      subtitle: "Lean out, keep muscle", icon: "scissors")
                    goalCard(.maintain, title: "Maintain", subtitle: "Hold bodyweight",        icon: "scope")
                    goalCard(.bulk,     title: "Build",    subtitle: "Gain muscle",            icon: "bolt.fill")
                }
                .padding(.top, Theme.Spacing.s)
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.bottom, 120)
        }
    }

    private func goalCard(_ g: FitnessGoal,
                          title: String,
                          subtitle: String,
                          icon: String) -> some View {
        let active = viewModel.goal == g
        return Button {
            viewModel.goal = g
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(active ? .white : Theme.Colors.indigo)
                    .frame(width: 44, height: 44)
                    .background(active ? Color.white.opacity(0.2) : Theme.Colors.indigo.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.Fonts.display(20))
                        .foregroundStyle(active ? .white : Theme.Colors.ink)
                    Text(subtitle)
                        .font(Theme.Fonts.ui(12))
                        .foregroundStyle(active ? Color.white.opacity(0.8) : Theme.Colors.ink3)
                }
                Spacer()
                if active {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(active ? Theme.Colors.ink : Theme.Colors.paper)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.l)
                    .stroke(active ? Theme.Colors.ink : Theme.Colors.line, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l))
        }
        .buttonStyle(.plain)
    }
}
