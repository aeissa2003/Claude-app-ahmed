import SwiftUI

struct WorkoutDetailView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.userProfile) private var profile
    let workout: Workout
    @State private var showingEditor = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                header
                ForEach(workout.exercises) { ex in
                    exerciseCard(ex, units: profile?.unitsPref ?? .metric)
                }
                if let notes = workout.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes").font(.headline)
                        Text(notes).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showingEditor = true }
            }
        }
        .sheet(isPresented: $showingEditor) {
            WorkoutEditorView(uid: workout.ownerUid, editing: workout)
                .environment(env)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(workout.startedAt.formatted(date: .complete, time: .shortened))
                .font(.headline)
            HStack(spacing: Theme.Spacing.m) {
                if let ended = workout.endedAt {
                    Text("\(Int(ended.timeIntervalSince(workout.startedAt) / 60)) min")
                }
                Text("\(workout.exercises.count) exercise\(workout.exercises.count == 1 ? "" : "s")")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private func exerciseCard(_ ex: WorkoutExercise, units: UnitsPreference) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack {
                Text(ex.exerciseName).font(.subheadline.bold())
                Spacer()
                Text(ex.kind.rawValue.capitalized)
                    .font(.caption2)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(Capsule())
            }
            ForEach(ex.sets) { set in
                HStack {
                    Text("Set \(set.order + 1)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 50, alignment: .leading)
                    Text(setDescription(set, kind: ex.kind, units: units))
                        .font(.footnote)
                    Spacer()
                    if set.completed {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Theme.Colors.protein)
                            .font(.caption)
                    }
                }
            }
            if let notes = ex.notes, !notes.isEmpty {
                Text(notes).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(Theme.Spacing.m)
        .background(Color.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
    }

    private func setDescription(_ set: WorkoutSet, kind: ExerciseKind, units: UnitsPreference) -> String {
        switch kind {
        case .strength:
            let weight = UnitConversion.formatLiftWeight(kg: set.weightKg ?? 0, units: units)
            return "\(weight) × \(set.reps ?? 0) reps"
        case .bodyweight:
            return "\(set.reps ?? 0) reps"
        case .cardio:
            let minutes = (set.durationSeconds ?? 0) / 60
            if let distM = set.distanceM, distM > 0 {
                let dist = units == .metric
                    ? String(format: "%.2f km", distM / 1000)
                    : String(format: "%.2f mi", distM / 1609.344)
                return "\(minutes) min · \(dist)"
            }
            return "\(minutes) min"
        }
    }
}
