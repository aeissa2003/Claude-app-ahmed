import SwiftUI

struct BasicsStep: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("STEP 2 OF 6")
                    .font(Theme.Fonts.mono(10, weight: .semibold))
                    .tracking(1.0)
                    .foregroundStyle(Theme.Colors.indigo)

                Text("The basics.")
                    .font(Theme.Fonts.display(34))
                    .tracking(-1.0)

                Text("We use these to estimate a starting protein and calorie target. You can edit them later.")
                    .font(Theme.Fonts.ui(14))
                    .foregroundStyle(Theme.Colors.ink3)

                // Sex picker as chips
                VStack(alignment: .leading, spacing: 8) {
                    PCEyebrow(text: "Sex")
                    HStack(spacing: 8) {
                        sexChip(.male, "Male")
                        sexChip(.female, "Female")
                        sexChip(.other, "Other")
                        sexChip(.preferNotToSay, "Prefer not")
                    }
                }
                .padding(.top, 4)

                // Age / height / weight cards
                HStack(spacing: 10) {
                    numberCell(label: "Age",
                               value: "\(viewModel.age)",
                               unit: "yrs",
                               onMinus: { if viewModel.age > 10 { viewModel.age -= 1 } },
                               onPlus:  { viewModel.age += 1 })
                    numberCell(label: "Height",
                               value: "\(Int(viewModel.heightCm))",
                               unit: "cm",
                               onMinus: { viewModel.heightCm = max(120, viewModel.heightCm - 1) },
                               onPlus:  { viewModel.heightCm += 1 })
                    numberCell(label: "Weight",
                               value: String(format: "%.0f", viewModel.weightKg),
                               unit: "kg",
                               onMinus: { viewModel.weightKg = max(30, viewModel.weightKg - 1) },
                               onPlus:  { viewModel.weightKg += 1 })
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.bottom, 120)
        }
    }

    private func sexChip(_ s: Sex, _ label: String) -> some View {
        PCChip(text: label, style: viewModel.sex == s ? .active : .neutral) {
            viewModel.sex = s
        }
    }

    private func numberCell(label: String,
                            value: String,
                            unit: String,
                            onMinus: @escaping () -> Void,
                            onPlus: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            PCEyebrow(text: label)
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(Theme.Fonts.display(26))
                    .tracking(-0.5)
                Text(unit)
                    .font(Theme.Fonts.ui(11))
                    .foregroundStyle(Theme.Colors.ink3)
            }
            HStack(spacing: 8) {
                smallRound(systemName: "minus", action: onMinus)
                smallRound(systemName: "plus",  action: onPlus)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.paper)
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.m).stroke(Theme.Colors.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
    }

    private func smallRound(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 10, weight: .bold))
                .frame(width: 22, height: 22)
                .background(Theme.Colors.ink.opacity(0.08))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
