import SwiftUI

struct WelcomeStep: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("STEP 1 OF 6")
                    .font(Theme.Fonts.mono(10, weight: .semibold))
                    .tracking(1.0)
                    .foregroundStyle(Theme.Colors.indigo)

                Text("Welcome.\nWhat should\nwe call you?")
                    .font(Theme.Fonts.display(36))
                    .tracking(-1.3)
                    .foregroundStyle(Theme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text("A few quick questions so we can personalize your protein target and suggest recipes that fit.")
                    .font(Theme.Fonts.ui(14))
                    .foregroundStyle(Theme.Colors.ink3)

                VStack(alignment: .leading, spacing: 8) {
                    PCEyebrow(text: "Display name")
                    TextField("e.g. Ahmed", text: $viewModel.displayName)
                        .textContentType(.name)
                        .font(Theme.Fonts.display(22))
                        .tracking(-0.3)
                        .padding(.vertical, 12)
                    Rectangle().fill(Theme.Colors.line2).frame(height: 1)
                    Text("This is what friends see on your recipes and comments.")
                        .font(Theme.Fonts.ui(12))
                        .foregroundStyle(Theme.Colors.ink3)
                }
                .padding(.top, Theme.Spacing.s)
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.bottom, 120)
        }
    }
}
