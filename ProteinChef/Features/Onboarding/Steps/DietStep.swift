import SwiftUI

struct DietStep: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("STEP 5 OF 6")
                    .font(Theme.Fonts.mono(10, weight: .semibold))
                    .tracking(1.0)
                    .foregroundStyle(Theme.Colors.indigo)

                Text("Any dietary\nrestrictions?")
                    .font(Theme.Fonts.display(34))
                    .tracking(-1.0)
                    .fixedSize(horizontal: false, vertical: true)

                Text("We'll filter ingredient suggestions. Tap Skip in the top right if none apply.")
                    .font(Theme.Fonts.ui(14))
                    .foregroundStyle(Theme.Colors.ink3)

                let cols = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
                LazyVGrid(columns: cols, spacing: 10) {
                    ForEach(DietaryRestriction.allCases, id: \.self) { r in
                        dietChip(r)
                    }
                }
                .padding(.top, Theme.Spacing.s)
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.bottom, 120)
        }
    }

    private func dietChip(_ r: DietaryRestriction) -> some View {
        let active = viewModel.diet.contains(r)
        return Button {
            if active { viewModel.diet.remove(r) }
            else      { viewModel.diet.insert(r) }
        } label: {
            HStack {
                Text(label(for: r))
                    .font(Theme.Fonts.ui(14, weight: .semibold))
                Spacer()
                if active {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(active ? Theme.Colors.ink : Theme.Colors.paper)
            .foregroundStyle(active ? .white : Theme.Colors.ink)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.m)
                    .stroke(active ? Theme.Colors.ink : Theme.Colors.line, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
        }
        .buttonStyle(.plain)
    }

    private func label(for r: DietaryRestriction) -> String {
        switch r {
        case .vegetarian: "Vegetarian"
        case .vegan:      "Vegan"
        case .pescatarian:"Pescatarian"
        case .halal:      "Halal"
        case .kosher:     "Kosher"
        case .glutenFree: "Gluten-free"
        case .dairyFree:  "Dairy-free"
        case .nutFree:    "Nut-free"
        }
    }
}
