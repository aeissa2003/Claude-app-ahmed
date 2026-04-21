import SwiftUI

struct WorkoutsPlaceholderView: View {
    var body: some View {
        PhasePlaceholderView(
            phase: 5,
            feature: "Workouts",
            blurb: "Log exercises with individual per-set weights and reps. Save and reuse templates. Coming in Phase 5."
        )
    }
}
