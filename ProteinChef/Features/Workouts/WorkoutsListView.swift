import SwiftUI

struct WorkoutsListView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.userProfile) private var profile

    @State private var workouts: [Workout] = []
    @State private var loadError: String?
    @State private var presenting: Presented?

    enum Presented: Identifiable {
        case active
        case activeFrom(WorkoutTemplate)
        case logPast
        case templates
        var id: String {
            switch self {
            case .active: return "active"
            case .activeFrom(let t): return "activeFrom:\(t.id)"
            case .logPast: return "logPast"
            case .templates: return "templates"
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        presenting = .active
                    } label: {
                        actionLabel(title: "Start workout", detail: "Live session with timer", icon: "bolt.heart.fill", tint: Theme.Colors.protein)
                    }
                    Button {
                        presenting = .logPast
                    } label: {
                        actionLabel(title: "Log past workout", detail: "Enter a session after the fact", icon: "pencil.and.list.clipboard", tint: Theme.Colors.kcal)
                    }
                    Button {
                        presenting = .templates
                    } label: {
                        actionLabel(title: "Templates", detail: "Reusable workout plans", icon: "doc.on.doc", tint: Theme.Colors.carbs)
                    }
                }

                if workouts.isEmpty {
                    Section {
                        ContentUnavailableView {
                            Label("No workouts yet", systemImage: "dumbbell")
                        } description: {
                            Text("Tap Start workout to begin a live session, or log a past one.")
                        }
                        .listRowBackground(Color.clear)
                    }
                } else {
                    Section("History") {
                        ForEach(workouts) { workout in
                            NavigationLink(value: workout) {
                                WorkoutHistoryRow(workout: workout, units: profile?.unitsPref ?? .metric)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("Workouts")
            .navigationDestination(for: Workout.self) { workout in
                WorkoutDetailView(workout: workout)
            }
            .sheet(item: $presenting) { p in
                switch p {
                case .active:
                    if let uid = env.auth.currentUid {
                        ActiveWorkoutView(uid: uid).environment(env)
                    }
                case .activeFrom(let template):
                    if let uid = env.auth.currentUid {
                        ActiveWorkoutView(uid: uid, seedTemplate: template).environment(env)
                    }
                case .logPast:
                    if let uid = env.auth.currentUid {
                        WorkoutEditorView(uid: uid).environment(env)
                    }
                case .templates:
                    WorkoutTemplatesListView(onStart: { template in
                        presenting = .activeFrom(template)
                    })
                    .environment(env)
                }
            }
            .task(id: env.auth.currentUid ?? "") {
                await subscribe()
            }
            .alert("Couldn’t load workouts", isPresented: .constant(loadError != nil)) {
                Button("OK") { loadError = nil }
            } message: { Text(loadError ?? "") }
        }
    }

    private func actionLabel(title: String, detail: String, icon: String, tint: Color) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline).foregroundStyle(.primary)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private func subscribe() async {
        guard let uid = env.auth.currentUid else { return }
        do {
            for try await list in env.workouts.listStream(ownerUid: uid) {
                workouts = list
            }
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func delete(at offsets: IndexSet) {
        guard let uid = env.auth.currentUid else { return }
        let toDelete = offsets.map { workouts[$0] }
        Task {
            for workout in toDelete {
                try? await env.workouts.delete(ownerUid: uid, id: workout.id)
            }
        }
    }
}

struct WorkoutHistoryRow: View {
    let workout: Workout
    let units: UnitsPreference

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(workout.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline.bold())
                Spacer()
                Text(durationText).font(.caption).foregroundStyle(.secondary)
            }
            Text(summary)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let templateName = workout.templateName {
                Text("Template · \(templateName)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }

    private var durationText: String {
        guard let ended = workout.endedAt else { return "in progress" }
        let minutes = Int(ended.timeIntervalSince(workout.startedAt) / 60)
        return "\(minutes) min"
    }

    private var summary: String {
        let exCount = workout.exercises.count
        let totalSets = workout.exercises.reduce(0) { $0 + $1.sets.count }
        return "\(exCount) exercise\(exCount == 1 ? "" : "s") · \(totalSets) set\(totalSets == 1 ? "" : "s")"
    }
}
