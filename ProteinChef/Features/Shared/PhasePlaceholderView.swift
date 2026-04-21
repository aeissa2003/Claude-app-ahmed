import SwiftUI

/// Temporary placeholder shown for features that haven't been implemented yet.
/// Replaced module-by-module as the phased build plan in README.md progresses.
struct PhasePlaceholderView: View {
    let phase: Int
    let feature: String
    let blurb: String

    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Phase \(phase): \(feature)", systemImage: "hammer.fill")
            } description: {
                Text(blurb)
            }
            .navigationTitle(feature)
        }
    }
}
