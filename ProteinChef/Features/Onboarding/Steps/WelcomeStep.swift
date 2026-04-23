import SwiftUI

struct WelcomeStep: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        Form {
            Section {
                VStack(spacing: Theme.Spacing.m) {
                    Image(systemName: "fork.knife.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(Theme.Colors.protein)
                    Text("Welcome!")
                        .font(.title.bold())
                    Text("A few quick questions so we can personalize your protein target and recipe suggestions.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }

            Section {
                TextField("e.g. Ahmed", text: $viewModel.displayName)
                    .textContentType(.name)
            } header: {
                Text("Your name")
            } footer: {
                Text("This is what friends see on your recipes and comments. You can change it later.")
            }
        }
    }
}
