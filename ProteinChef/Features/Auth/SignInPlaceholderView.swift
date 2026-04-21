import SwiftUI

struct SignInPlaceholderView: View {
    var body: some View {
        PhasePlaceholderView(
            phase: 2,
            feature: "Sign in",
            blurb: "Sign in with Apple, Google, and email/password arrives in Phase 2."
        )
    }
}
