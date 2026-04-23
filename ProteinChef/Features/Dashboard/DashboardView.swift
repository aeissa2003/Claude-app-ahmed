import SwiftUI

struct DashboardView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.userProfile) private var profile

    @State private var showingLogSheet = false
    @State private var showingInbox = false

    private let day = Date()

    var body: some View {
        ZStack(alignment: .top) {
            Theme.Colors.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                PCAppBar(title: "Today", eyebrow: todayLabel) {
                    HStack(spacing: 8) {
                        PCIconButton(systemName: "bell", variant: .paper) {
                            showingInbox = true
                        }
                        PCIconButton(systemName: "plus", variant: .ink) {
                            showingLogSheet = true
                        }
                    }
                }
                DayDashboardView(day: day)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showingLogSheet) {
            if let uid = env.auth.currentUid {
                LogMealSheet(uid: uid, day: day)
                    .environment(env)
            }
        }
        .sheet(isPresented: $showingInbox) {
            NotificationsView().environment(env)
        }
    }

    private var todayLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEE · MMM d"
        return f.string(from: day)
    }
}
