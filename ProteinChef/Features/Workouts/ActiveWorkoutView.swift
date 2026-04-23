import Combine
import SwiftUI

/// Live-session workout view. Shares the editor view model, but adds an elapsed-time
/// header, a manually-started rest timer, and a Finish action that sets endedAt.
struct ActiveWorkoutView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.userProfile) private var profile
    @Environment(\.dismiss) private var dismiss

    @State private var vm: WorkoutEditorViewModel
    @State private var rest = RestTimer()
    @State private var now: Date = Date()
    @State private var showingExercisePicker = false
    @State private var showingFinishConfirm = false
    @State private var showingCancelConfirm = false

    init(uid: String, seedTemplate: WorkoutTemplate? = nil) {
        _vm = State(initialValue: WorkoutEditorViewModel(uid: uid, seedTemplate: seedTemplate))
    }

    var body: some View {
        NavigationStack {
            Form {
                elapsedHeader
                restSection

                ForEach($vm.exercises) { $exercise in
                    exerciseSection(exercise: $exercise)
                }

                Section {
                    Button {
                        showingExercisePicker = true
                    } label: {
                        Label("Add exercise", systemImage: "plus.circle.fill")
                    }
                }

                Section("Notes") {
                    TextField("Optional notes", text: $vm.notes, axis: .vertical)
                        .lineLimit(1...6)
                }
            }
            .navigationTitle("Active workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingCancelConfirm = true }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Finish") { showingFinishConfirm = true }
                        .fontWeight(.semibold)
                        .disabled(!vm.isValid || vm.isSaving)
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView { picked in
                    vm.addExercise(picked)
                }
                .environment(env)
            }
            .alert("Finish workout?", isPresented: $showingFinishConfirm) {
                Button("Finish") { Task { await finish() } }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Saves the session and stops the timer.")
            }
            .alert("Discard workout?", isPresented: $showingCancelConfirm) {
                Button("Discard", role: .destructive) {
                    rest.stop()
                    dismiss()
                }
                Button("Keep editing", role: .cancel) {}
            }
            .alert("Couldn’t save", isPresented: .constant(vm.errorText != nil)) {
                Button("OK") { vm.errorText = nil }
            } message: { Text(vm.errorText ?? "") }
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { t in
                now = t
            }
            .onDisappear { rest.stop() }
        }
    }

    // MARK: - Sections

    private var elapsedHeader: some View {
        Section {
            VStack(spacing: 6) {
                Text(elapsedText)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.Colors.protein)
                    .monospacedDigit()
                Text("Started \(vm.startedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var elapsedText: String {
        let elapsed = Int(now.timeIntervalSince(vm.startedAt))
        let hh = elapsed / 3600
        let mm = (elapsed % 3600) / 60
        let ss = elapsed % 60
        return hh > 0
            ? String(format: "%d:%02d:%02d", hh, mm, ss)
            : String(format: "%02d:%02d", mm, ss)
    }

    private var restSection: some View {
        Section("Rest timer") {
            HStack {
                Text(rest.displayText)
                    .font(.title3.monospacedDigit().bold())
                    .foregroundStyle(rest.isRunning ? Theme.Colors.kcal : .primary)
                Spacer()
                Button {
                    rest.adjust(by: -15)
                } label: {
                    Image(systemName: "minus.circle")
                }
                .buttonStyle(.plain)
                Button {
                    rest.adjust(by: 15)
                } label: {
                    Image(systemName: "plus.circle")
                }
                .buttonStyle(.plain)
                Button {
                    if rest.isRunning { rest.stop() } else { rest.start() }
                } label: {
                    Text(rest.isRunning ? "Stop" : "Start")
                        .fontWeight(.semibold)
                        .frame(minWidth: 60)
                }
                .buttonStyle(.borderedProminent)
                .tint(rest.isRunning ? .red : Theme.Colors.protein)
            }
        }
    }

    @ViewBuilder
    private func exerciseSection(exercise: Binding<WorkoutExercise>) -> some View {
        let units = profile?.unitsPref ?? .metric
        Section {
            HStack {
                Text(exercise.wrappedValue.exerciseName).font(.headline)
                Spacer()
                Button(role: .destructive) {
                    if let idx = vm.exercises.firstIndex(where: { $0.id == exercise.wrappedValue.id }) {
                        vm.removeExercise(at: IndexSet(integer: idx))
                    }
                } label: {
                    Image(systemName: "trash").font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red.opacity(0.8))
            }

            ForEach(exercise.sets) { $set in
                activeSetRow(
                    set: $set,
                    kind: exercise.wrappedValue.kind,
                    units: units,
                    exerciseId: exercise.wrappedValue.id
                )
            }
            .onDelete { offsets in
                vm.removeSet(fromExercise: exercise.wrappedValue.id, at: offsets)
            }

            Button {
                vm.addSet(toExercise: exercise.wrappedValue.id)
            } label: {
                Label("Add set", systemImage: "plus")
            }
            .font(.footnote)
        }
    }

    private func activeSetRow(
        set: Binding<WorkoutSet>,
        kind: ExerciseKind,
        units: UnitsPreference,
        exerciseId: String
    ) -> some View {
        HStack(spacing: 8) {
            Text("\(set.wrappedValue.order + 1)")
                .frame(width: 20, alignment: .leading)
                .font(.footnote)
                .foregroundStyle(.secondary)

            switch kind {
            case .strength:
                doubleField("wt", weightBinding(set: set, units: units))
                intField("reps", repsBinding(set: set))
            case .bodyweight:
                intField("reps", repsBinding(set: set))
            case .cardio:
                intField("min", minutesBinding(set: set))
                doubleField(units == .metric ? "km" : "mi", distanceBinding(set: set, units: units))
            }

            Spacer()

            Button {
                vm.toggleSetCompleted(exerciseId: exerciseId, setId: set.wrappedValue.id)
                if set.wrappedValue.completed && !rest.isRunning {
                    // Just marked complete — leave timer start manual per design choice.
                    // User taps Start on the rest section.
                }
            } label: {
                Image(systemName: set.wrappedValue.completed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(set.wrappedValue.completed ? Theme.Colors.protein : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
    }

    private func doubleField(_ label: String, _ binding: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            TextField(label, value: binding, format: .number.precision(.fractionLength(0...2)))
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 66)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func intField(_ label: String, _ binding: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            TextField(label, value: binding, format: .number)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 66)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func weightBinding(set: Binding<WorkoutSet>, units: UnitsPreference) -> Binding<Double> {
        Binding(
            get: {
                let kg = set.wrappedValue.weightKg ?? 0
                return units == .metric ? kg : UnitConversion.lb(fromKg: kg)
            },
            set: { newVal in
                set.wrappedValue.weightKg = units == .metric ? newVal : UnitConversion.kg(fromLb: newVal)
            }
        )
    }

    private func repsBinding(set: Binding<WorkoutSet>) -> Binding<Int> {
        Binding(
            get: { set.wrappedValue.reps ?? 0 },
            set: { set.wrappedValue.reps = $0 }
        )
    }

    private func minutesBinding(set: Binding<WorkoutSet>) -> Binding<Int> {
        Binding(
            get: { (set.wrappedValue.durationSeconds ?? 0) / 60 },
            set: { set.wrappedValue.durationSeconds = $0 * 60 }
        )
    }

    private func distanceBinding(set: Binding<WorkoutSet>, units: UnitsPreference) -> Binding<Double> {
        Binding(
            get: {
                let m = set.wrappedValue.distanceM ?? 0
                return units == .metric ? m / 1000 : m / 1609.344
            },
            set: { newVal in
                set.wrappedValue.distanceM = units == .metric ? newVal * 1000 : newVal * 1609.344
            }
        )
    }

    // MARK: - Finish

    private func finish() async {
        vm.endedAt = Date()
        vm.isSaving = true
        defer { vm.isSaving = false }
        do {
            try await env.workouts.save(vm.snapshot())
            rest.stop()
            dismiss()
        } catch {
            vm.errorText = error.localizedDescription
        }
    }
}
