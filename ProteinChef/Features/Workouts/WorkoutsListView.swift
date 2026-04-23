import SwiftUI

struct WorkoutsListView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.userProfile) private var profile

    @State private var workouts: [Workout] = []
    @State private var templates: [WorkoutTemplate] = []
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
            ZStack(alignment: .top) {
                Theme.Colors.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    PCAppBar(title: "Train", eyebrow: weekLabel) {
                        PCIconButton(systemName: "plus", variant: .ink) {
                            presenting = .logPast
                        }
                    }
                    ScrollView {
                        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                            nextUpCard
                            statsRow
                            templatesCarousel
                            historySection
                        }
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.bottom, 140)
                    }
                }
            }
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
                async let a: () = subscribeWorkouts()
                async let b: () = subscribeTemplates()
                _ = await (a, b)
            }
            .alert("Couldn’t load workouts", isPresented: .constant(loadError != nil)) {
                Button("OK") { loadError = nil }
            } message: { Text(loadError ?? "") }
        }
    }

    // MARK: - Derived

    private var weekLabel: String {
        let cal = Calendar.current
        let weekNumber = cal.component(.weekOfYear, from: Date())
        let weekWorkouts = workouts.filter {
            cal.component(.weekOfYear, from: $0.startedAt) == weekNumber
        }
        return "Week \(weekNumber) · \(weekWorkouts.count) of 4 done"
    }

    // MARK: - Next up card (indigo)

    @ViewBuilder
    private var nextUpCard: some View {
        let next = templates.first ?? nextTemplatePlaceholder
        PCCard(style: .indigo, padding: 22) {
            VStack(alignment: .leading, spacing: 14) {
                PCEyebrow(text: "Next up", color: Color.white.opacity(0.75))
                Text(next.name)
                    .font(Theme.Fonts.display(30))
                    .tracking(-0.8)
                    .foregroundStyle(.white)
                HStack(spacing: 16) {
                    metaChip("\(next.exercises.count) EXERCISES")
                    metaChip("~\(next.exercises.count * 8) MIN")
                    if let workout = workouts.first {
                        let mins = Int((workout.endedAt ?? Date()).timeIntervalSince(workout.startedAt) / 60)
                        metaChip("LAST \(mins) MIN")
                    }
                }
                Button {
                    presenting = templates.isEmpty ? .active : .activeFrom(next)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                        Text("Start workout")
                            .font(Theme.Fonts.ui(15, weight: .semibold))
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Theme.Colors.lime)
                    .foregroundStyle(Theme.Colors.limeInk)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var nextTemplatePlaceholder: WorkoutTemplate {
        WorkoutTemplate(id: "stub", ownerUid: "",
                        name: "Freestyle session",
                        exercises: [],
                        createdAt: Date(), updatedAt: Date())
    }

    private func metaChip(_ text: String) -> some View {
        Text(text)
            .font(Theme.Fonts.mono(10))
            .tracking(0.8)
            .foregroundStyle(Color.white.opacity(0.85))
    }

    // MARK: - Stats row

    private var statsRow: some View {
        HStack(spacing: 10) {
            PCStatTile(value: "\(workouts.count)", label: "Workouts")
            PCStatTile(value: formattedVolume, label: "Volume")
            PCStatTile(value: "\(prCount)", label: "PRs this week")
        }
    }

    private var formattedVolume: String {
        let total = workouts.reduce(0.0) { acc, w in
            acc + w.exercises.reduce(0.0) { exAcc, ex in
                exAcc + ex.sets.reduce(0.0) { setAcc, set in
                    setAcc + (set.weightKg ?? 0) * Double(set.reps ?? 0)
                }
            }
        }
        if total >= 1000 {
            return String(format: "%.1fk", total / 1000)
        }
        return "\(Int(total))"
    }

    private var prCount: Int {
        // Placeholder: real PR logic arrives with set-comparison.
        0
    }

    // MARK: - Templates carousel

    @ViewBuilder
    private var templatesCarousel: some View {
        if !templates.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                HStack(alignment: .lastTextBaseline) {
                    Text("Templates").font(Theme.Fonts.sectionTitle).tracking(-0.5)
                    Spacer()
                    PCEyebrow(text: "\(templates.count) saved")
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(templates) { template in
                            Button { presenting = .activeFrom(template) } label: {
                                templateCard(template)
                            }
                            .buttonStyle(.plain)
                        }
                        Button { presenting = .templates } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Image(systemName: "plus")
                                    .foregroundStyle(Theme.Colors.ink3)
                                    .frame(width: 36, height: 36)
                                    .background(Theme.Colors.ink.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                Text("Manage templates")
                                    .font(Theme.Fonts.ui(13, weight: .semibold))
                                    .foregroundStyle(Theme.Colors.ink)
                                PCEyebrow(text: "Reusable plans")
                            }
                            .padding(14)
                            .frame(width: 170, alignment: .leading)
                            .background(Theme.Colors.paper)
                            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.m)
                                        .stroke(Theme.Colors.line, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func templateCard(_ t: WorkoutTemplate) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "dumbbell.fill")
                .foregroundStyle(Theme.Colors.indigo)
                .frame(width: 36, height: 36)
                .background(Theme.Colors.indigo.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            Text(t.name)
                .font(Theme.Fonts.ui(14, weight: .semibold))
                .foregroundStyle(Theme.Colors.ink)
            PCEyebrow(text: "\(t.exercises.count) exercises")
        }
        .padding(14)
        .frame(width: 170, alignment: .leading)
        .background(Theme.Colors.paper)
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.m).stroke(Theme.Colors.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
    }

    // MARK: - History

    @ViewBuilder
    private var historySection: some View {
        if workouts.isEmpty {
            ContentUnavailableView {
                Label("No workouts yet", systemImage: "dumbbell")
            } description: {
                Text("Tap Start workout to begin a live session, or log a past one with +.")
            }
        } else {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text("History").font(Theme.Fonts.sectionTitle).tracking(-0.5)
                VStack(spacing: 8) {
                    ForEach(workouts) { workout in
                        NavigationLink(value: workout) {
                            historyRow(workout)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func historyRow(_ w: Workout) -> some View {
        let volume = w.exercises.flatMap(\.sets)
            .reduce(0.0) { $0 + (($1.weightKg ?? 0) * Double($1.reps ?? 0)) }
        let sets = w.exercises.reduce(0) { $0 + $1.sets.count }
        let duration: String = {
            guard let ended = w.endedAt else { return "in progress" }
            return "\(Int(ended.timeIntervalSince(w.startedAt) / 60))m"
        }()

        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(w.templateName ?? "Freestyle")
                        .font(Theme.Fonts.ui(15, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink)
                }
                Text("\(w.startedAt.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())) · \(duration) · \(sets) sets")
                    .font(Theme.Fonts.mono(10))
                    .foregroundStyle(Theme.Colors.ink3)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(volume))")
                    .font(Theme.Fonts.display(22))
                    .foregroundStyle(Theme.Colors.ink)
                PCEyebrow(text: "kg volume")
            }
        }
        .padding(14)
        .background(Theme.Colors.paper)
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.m).stroke(Theme.Colors.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
    }

    // MARK: - Data

    private func subscribeWorkouts() async {
        guard let uid = env.auth.currentUid else { return }
        do {
            for try await list in env.workouts.listStream(ownerUid: uid) {
                workouts = list
            }
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func subscribeTemplates() async {
        guard let uid = env.auth.currentUid else { return }
        do {
            for try await list in env.workoutTemplates.listStream(ownerUid: uid) {
                templates = list
            }
        } catch {
            // Non-fatal — templates just won't show.
        }
    }
}
