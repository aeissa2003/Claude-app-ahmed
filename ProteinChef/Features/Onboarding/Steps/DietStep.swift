import SwiftUI

struct DietStep: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        Form {
            Section {
                ForEach(DietaryRestriction.allCases, id: \.self) { restriction in
                    Toggle(label(for: restriction), isOn: binding(for: restriction))
                }
            } header: {
                Text("Dietary restrictions")
            } footer: {
                Text("We'll filter ingredient suggestions. Tap 'Skip' in the top right if none apply.")
            }
        }
    }

    private func binding(for restriction: DietaryRestriction) -> Binding<Bool> {
        Binding(
            get: { viewModel.diet.contains(restriction) },
            set: { isOn in
                if isOn { viewModel.diet.insert(restriction) }
                else    { viewModel.diet.remove(restriction) }
            }
        )
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
