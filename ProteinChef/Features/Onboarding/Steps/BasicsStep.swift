import SwiftUI

struct BasicsStep: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        Form {
            Section("You") {
                Picker("Sex", selection: $viewModel.sex) {
                    Text("Male").tag(Sex.male)
                    Text("Female").tag(Sex.female)
                    Text("Other").tag(Sex.other)
                    Text("Prefer not to say").tag(Sex.preferNotToSay)
                }
                Stepper(value: $viewModel.age, in: 10...100) {
                    HStack {
                        Text("Age")
                        Spacer()
                        Text("\(viewModel.age)").foregroundStyle(.secondary)
                    }
                }
            }

            Section("Measurements") {
                LabeledContent("Height") {
                    HStack {
                        TextField("cm", value: $viewModel.heightCm, format: .number.precision(.fractionLength(0)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("cm").foregroundStyle(.secondary)
                    }
                }
                LabeledContent("Weight") {
                    HStack {
                        TextField("kg", value: $viewModel.weightKg, format: .number.precision(.fractionLength(1)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("kg").foregroundStyle(.secondary)
                    }
                }
            } footer: {
                Text("You can switch to imperial units (lb, ft/in) in Settings later.")
            }
        }
    }
}
