import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Today", systemImage: "chart.bar.fill") }
            RecipesListView()
                .tabItem { Label("Recipes", systemImage: "fork.knife") }
            WorkoutsListView()
                .tabItem { Label("Workouts", systemImage: "dumbbell.fill") }
            FeedView()
                .tabItem { Label("Friends", systemImage: "person.2.fill") }
            SettingsPlaceholderView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}
