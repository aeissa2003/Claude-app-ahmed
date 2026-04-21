import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardPlaceholderView()
                .tabItem { Label("Today", systemImage: "chart.bar.fill") }
            RecipesPlaceholderView()
                .tabItem { Label("Recipes", systemImage: "fork.knife") }
            WorkoutsPlaceholderView()
                .tabItem { Label("Workouts", systemImage: "dumbbell.fill") }
            FeedPlaceholderView()
                .tabItem { Label("Friends", systemImage: "person.2.fill") }
            SettingsPlaceholderView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}
