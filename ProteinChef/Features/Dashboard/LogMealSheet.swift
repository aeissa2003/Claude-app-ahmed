import SwiftUI

/// Bottom-sheet chooser for logging a meal. Presents a 3-tab segmented control
/// (Saved recipe / Quick add / Scan) matching the athletic-editorial redesign.
/// The Saved tab routes to RecipePickerForLoggingSheet; the Quick tab routes to
/// LogAdHocSheet. Scan is a stub.
struct LogMealSheet: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    let uid: String
    let day: Date
    var initialMealType: MealType?

    @State private var tab: Tab = .saved
    @State private var route: Route?

    enum Tab: Hashable { case saved, quick, scan }
    enum Route: Identifiable {
        case recipe, adHoc
        var id: String { self == .recipe ? "recipe" : "adHoc" }
    }

    var body: some View {
        ZStack {
            Theme.Colors.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                PCSegmented(selection: $tab, options: [
                    (.saved, "Saved Recipe"),
                    (.quick, "Quick Add"),
                    (.scan,  "Scan"),
                ])
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.top, 4)
                .padding(.bottom, Theme.Spacing.m)

                content
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(Theme.Radius.xl)
        .presentationDragIndicator(.visible)
        .sheet(item: $route) { route in
            switch route {
            case .recipe:
                RecipePickerForLoggingSheet(uid: uid, day: day, initialMealType: initialMealType) {
                    self.route = nil
                    dismiss()
                }
                .environment(env)
            case .adHoc:
                LogAdHocSheet(uid: uid, day: day, initialMealType: initialMealType) {
                    self.route = nil
                    dismiss()
                }
                .environment(env)
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Log a meal")
                .font(Theme.Fonts.display(26))
                .tracking(-0.6)
            Spacer()
            PCIconButton(systemName: "xmark", variant: .paper) { dismiss() }
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.top, Theme.Spacing.m)
        .padding(.bottom, Theme.Spacing.s)
    }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .saved:
            routeCard(title: "From a recipe",
                      subtitle: "Pick one of your saved recipes.",
                      icon: "fork.knife",
                      cta: "Browse recipes") {
                route = .recipe
            }
        case .quick:
            routeCard(title: "Quick add",
                      subtitle: "Search the catalog or enter macros directly.",
                      icon: "bolt.fill",
                      cta: "Start typing") {
                route = .adHoc
            }
        case .scan:
            scanStub
        }
    }

    private func routeCard(title: String,
                           subtitle: String,
                           icon: String,
                           cta: String,
                           action: @escaping () -> Void) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.Colors.indigo)
                        .frame(width: 40, height: 40)
                        .background(Theme.Colors.indigo.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.s))
                    Spacer()
                }
                Text(title)
                    .font(Theme.Fonts.display(24))
                    .tracking(-0.5)
                Text(subtitle)
                    .font(Theme.Fonts.ui(14))
                    .foregroundStyle(Theme.Colors.ink3)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.paper)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.l)
                    .stroke(Theme.Colors.line, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l))

            PCButton(title: cta, systemImage: "arrow.right", style: .indigo, action: action)
        }
        .padding(.horizontal, Theme.Spacing.l)
    }

    private var scanStub: some View {
        VStack(spacing: Theme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.l)
                    .stroke(Theme.Colors.line2, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    .frame(height: 180)
                VStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(Theme.Colors.ink3)
                    Text("Barcode scan arrives soon.")
                        .font(Theme.Fonts.ui(13))
                        .foregroundStyle(Theme.Colors.ink3)
                }
            }
            PCButton(title: "Use Quick add instead",
                     systemImage: "bolt.fill",
                     style: .ghost) {
                tab = .quick
            }
        }
        .padding(.horizontal, Theme.Spacing.l)
    }
}
