import SwiftUI

struct DashboardView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.userProfile) private var profile

    /// Day offsets we keep rendered in the TabView, relative to today.
    /// Negative = past. 0 = today. Future days aren't shown.
    @State private var offsets: [Int] = Array((-30...0).reversed())
    @State private var selectedOffset: Int = 0
    @State private var showingLogSheet = false

    private var selectedDate: Date {
        Calendar.current.date(byAdding: .day, value: selectedOffset, to: Date()) ?? Date()
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedOffset) {
                ForEach(offsets, id: \.self) { offset in
                    let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                    DayDashboardView(day: date)
                        .tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(navTitle).font(.headline)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingLogSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Log a meal")
                    .disabled(Calendar.current.isDateInToday(selectedDate) == false && selectedOffset > 0)
                }
            }
            .sheet(isPresented: $showingLogSheet) {
                if let uid = env.auth.currentUid {
                    LogMealSheet(uid: uid, day: selectedDate)
                        .environment(env)
                }
            }
        }
    }

    private var navTitle: String {
        let cal = Calendar.current
        if cal.isDateInToday(selectedDate) { return "Today" }
        if cal.isDateInYesterday(selectedDate) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: selectedDate)
    }
}
