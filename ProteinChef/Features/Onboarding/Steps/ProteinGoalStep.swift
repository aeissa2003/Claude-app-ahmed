import SwiftUI

struct ProteinGoalStep: View {
    @Bindable var viewModel: OnboardingViewModel

    enum Preset { case maintain, build, cut
        var perKg: Double {
            switch self { case .maintain: 1.6; case .build: 2.2; case .cut: 2.4 }
        }
        var label: String {
            switch self { case .maintain: "MAINTAIN · KG"; case .build: "BUILD · KG"; case .cut: "CUT · KG" }
        }
    }

    private var currentPreset: Preset? {
        let perKg = viewModel.proteinGoalG / max(viewModel.weightKg, 1)
        if abs(perKg - 1.6) < 0.1 { return .maintain }
        if abs(perKg - 2.2) < 0.1 { return .build }
        if abs(perKg - 2.4) < 0.1 { return .cut }
        return nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("STEP 6 OF 6")
                    .font(Theme.Fonts.mono(10, weight: .semibold))
                    .tracking(1.0)
                    .foregroundStyle(Theme.Colors.indigo)

                Text("What's your\nprotein target?")
                    .font(Theme.Fonts.display(34))
                    .tracking(-1.0)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Typical recommendation: 1.6–2.2 g per kg of bodyweight for muscle building.")
                    .font(Theme.Fonts.ui(14))
                    .foregroundStyle(Theme.Colors.ink3)

                inkNumericCard
                    .padding(.top, Theme.Spacing.s)

                HStack(spacing: 10) {
                    presetCard(.maintain, grams: 1.6 * viewModel.weightKg)
                    presetCard(.build,    grams: 2.2 * viewModel.weightKg)
                    presetCard(.cut,      grams: 2.4 * viewModel.weightKg)
                }
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.bottom, 120)
        }
    }

    private var inkNumericCard: some View {
        VStack(spacing: 12) {
            PCEyebrow(text: "Daily target", color: Color.white.opacity(0.65))
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(Int(viewModel.proteinGoalG))")
                    .font(Theme.Fonts.display(90))
                    .tracking(-3)
                    .foregroundStyle(Theme.Colors.lime)
                VStack(alignment: .leading, spacing: 0) {
                    Text("g / day")
                        .font(Theme.Fonts.ui(12))
                        .foregroundStyle(Color.white.opacity(0.6))
                }
            }
            Text(metaLabel)
                .font(Theme.Fonts.mono(10))
                .tracking(1.0)
                .foregroundStyle(Color.white.opacity(0.6))

            Slider(value: $viewModel.proteinGoalG, in: 40...300, step: 5)
                .tint(Theme.Colors.lime)

            HStack {
                Text("40g")
                Spacer()
                Text("300g")
            }
            .font(Theme.Fonts.mono(10))
            .foregroundStyle(Color.white.opacity(0.45))
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.ink)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l))
    }

    private var metaLabel: String {
        let perKg = viewModel.proteinGoalG / max(viewModel.weightKg, 1)
        let goalWord: String = {
            switch viewModel.goal { case .cut: "CUT"; case .maintain: "MAINTAIN"; case .bulk: "MUSCLE BUILD" }
        }()
        return String(format: "%.1fG · KG · %@", perKg, goalWord)
    }

    private func presetCard(_ preset: Preset, grams: Double) -> some View {
        let active = currentPreset == preset
        return Button {
            viewModel.proteinGoalG = (grams / 5).rounded() * 5
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(Int(grams))g")
                    .font(Theme.Fonts.display(20))
                    .tracking(-0.3)
                    .foregroundStyle(active ? .white : Theme.Colors.ink)
                Text(preset.label)
                    .font(Theme.Fonts.mono(9, weight: .semibold))
                    .tracking(0.9)
                    .foregroundStyle(active ? Color.white.opacity(0.75) : Theme.Colors.ink3)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(active ? Theme.Colors.ink : Theme.Colors.paper)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.m)
                    .stroke(active ? Theme.Colors.ink : Theme.Colors.line, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
        }
        .buttonStyle(.plain)
    }
}
