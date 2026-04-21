import SwiftUI

struct OnboardingPlaceholderView: View {
    var body: some View {
        PhasePlaceholderView(
            phase: 2,
            feature: "Onboarding",
            blurb: "Bodyweight, height, age, sex, goal, dietary restrictions, and daily protein target are captured here in Phase 2."
        )
    }
}
