import SwiftUI

/// Entry chooser: "Log from a recipe" vs "Quick add (ad-hoc)".
struct LogMealSheet: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    let uid: String
    let day: Date

    @State private var route: Route?

    enum Route: Identifiable {
        case recipe
        case adHoc
        var id: String { self == .recipe ? "recipe" : "adHoc" }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        route = .recipe
                    } label: {
                        HStack(spacing: Theme.Spacing.m) {
                            Image(systemName: "fork.knife")
                                .foregroundStyle(Theme.Colors.protein)
                                .frame(width: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("From a recipe").font(.headline)
                                Text("Pick one of your saved recipes.")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)

                    Button {
                        route = .adHoc
                    } label: {
                        HStack(spacing: Theme.Spacing.m) {
                            Image(systemName: "bolt.fill")
                                .foregroundStyle(Theme.Colors.kcal)
                                .frame(width: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Quick add").font(.headline)
                                Text("Search the catalog or type macros manually.")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Log a meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(item: $route) { route in
                switch route {
                case .recipe:
                    RecipePickerForLoggingSheet(uid: uid, day: day) {
                        self.route = nil
                        dismiss()
                    }
                    .environment(env)
                case .adHoc:
                    LogAdHocSheet(uid: uid, day: day) {
                        self.route = nil
                        dismiss()
                    }
                    .environment(env)
                }
            }
        }
    }
}
