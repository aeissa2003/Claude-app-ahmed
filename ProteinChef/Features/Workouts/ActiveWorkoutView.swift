import Combine
import SwiftUI

/// Live-session workout view — dark surface per the redesign. Shares the editor
/// view model, adds an elapsed-time header, a rest timer pill, exercise cards
/// with the numbered-set / KG / REPS grid, and a Finish action that sets
/// endedAt and persists the workout.
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
        ZStack {
            Theme.Colors.darkBg.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(spacing: Theme.Spacing.md) {
                        restPill
                        ForEach($vm.exercises) { $exercise in
                            exerciseCard(exercise: $exercise)
                        }
                        addExerciseRow
                        notesBlock
                        Color.clear.frame(height: 40)
                    }
                    .padding(.horizontal, Theme.Spacing.l)
                    .padding(.top, Theme.Spacing.s)
                }
            }
        }
        .preferredColorScheme(.dark)
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

    // MARK: - Top bar

    private var topBar: some View {
        HStack(alignment: .center) {
            Button { showingCancelConfirm = true } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 36, height: 36)
                    .foregroundStyle(.white)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 2) {
                Text(sessionLabel.uppercased())
                    .font(Theme.Fonts.mono(10))
                    .tracking(1.0)
                    .foregroundStyle(Color.white.opacity(0.55))
                Text(elapsedText)
                    .font(Theme.Fonts.display(28))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }

            Spacer()

            Button { showingFinishConfirm = true } label: {
                Text("Finish")
                    .font(Theme.Fonts.ui(14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.limeInk)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Theme.Colors.lime)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!vm.isValid || vm.isSaving)
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.vertical, Theme.Spacing.s)
    }

    private var sessionLabel: String {
        "\(vm.templateName ?? "Workout") · elapsed"
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

    // MARK: - Rest pill

    private var restPill: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text("REST TIMER")
                    .font(Theme.Fonts.mono(10))
                    .tracking(1.0)
                    .foregroundStyle(Theme.Colors.lime.opacity(0.7))
                Text(rest.displayText)
                    .font(Theme.Fonts.display(44))
                    .foregroundStyle(Theme.Colors.lime)
                    .monospacedDigit()
            }
            Spacer()
            circleButton(text: "−15", action: { rest.adjust(by: -15) })
            circleButton(text: "+15", action: { rest.adjust(by: 15) })
            Button {
                if rest.isRunning { rest.stop() } else { rest.start() }
            } label: {
                Image(systemName: rest.isRunning ? "pause.fill" : "play.fill")
                    .foregroundStyle(Theme.Colors.limeInk)
                    .frame(width: 42, height: 42)
                    .background(Theme.Colors.lime)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Theme.Colors.lime.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.l)
                .stroke(Theme.Colors.lime.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l))
    }

    private func circleButton(text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(Theme.Fonts.ui(12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 36)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Exercise card

    private func exerciseCard(exercise: Binding<WorkoutExercise>) -> some View {
        let units = profile?.unitsPref ?? .metric
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.wrappedValue.exerciseName)
                        .font(Theme.Fonts.display(20))
                        .foregroundStyle(.white)
                    PCEyebrow(
                        text: "\(exercise.wrappedValue.kind.rawValue) · \(completedCount(exercise.wrappedValue))/\(exercise.wrappedValue.sets.count) sets",
                        color: Color.white.opacity(0.55)
                    )
                }
                Spacer()
                Menu {
                    Button(role: .destructive) {
                        if let idx = vm.exercises.firstIndex(where: { $0.id == exercise.wrappedValue.id }) {
                            vm.removeExercise(at: IndexSet(integer: idx))
                        }
                    } label: { Label("Remove", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(Color.white.opacity(0.7))
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
            }

            columnHeaders(kind: exercise.wrappedValue.kind, units: units)

            ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { idx, $set in
                setRow(set: $set,
                       setIndex: idx + 1,
                       kind: exercise.wrappedValue.kind,
                       units: units,
                       exerciseId: exercise.wrappedValue.id)
            }

            Button {
                vm.addSet(toExercise: exercise.wrappedValue.id)
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Add set")
                        .font(Theme.Fonts.mono(10))
                        .tracking(1.0)
                }
                .foregroundStyle(Color.white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.white.opacity(0.15),
                                      style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.l)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l))
    }

    private func completedCount(_ ex: WorkoutExercise) -> Int {
        ex.sets.filter { $0.completed }.count
    }

    private func columnHeaders(kind: ExerciseKind, units: UnitsPreference) -> some View {
        HStack(spacing: 10) {
            columnHeader("SET", width: 36, align: .leading)
            columnHeader("PREV", width: 60, align: .leading)
            switch kind {
            case .strength:
                columnHeader(units == .metric ? "KG" : "LB")
                columnHeader("REPS")
            case .bodyweight:
                columnHeader("REPS")
                Spacer().frame(maxWidth: .infinity)
            case .cardio:
                columnHeader("MIN")
                columnHeader(units == .metric ? "KM" : "MI")
            }
            Spacer().frame(width: 40)
        }
    }

    private func columnHeader(_ text: String,
                              width: CGFloat? = nil,
                              align: HorizontalAlignment = .center) -> some View {
        Text(text)
            .font(Theme.Fonts.mono(9, weight: .semibold))
            .tracking(0.9)
            .foregroundStyle(Color.white.opacity(0.45))
            .frame(width: width, alignment: Alignment(horizontal: align, vertical: .center))
            .frame(maxWidth: width == nil ? .infinity : nil)
    }

    // MARK: - Set row

    @ViewBuilder
    private func setRow(set: Binding<WorkoutSet>,
                        setIndex: Int,
                        kind: ExerciseKind,
                        units: UnitsPreference,
                        exerciseId: String) -> some View {
        let completed = set.wrappedValue.completed
        HStack(spacing: 10) {
            setIndexChip(setIndex, isPR: false, completed: completed)
            Text(previousText(set.wrappedValue, kind: kind, units: units))
                .font(Theme.Fonts.mono(11))
                .foregroundStyle(Color.white.opacity(0.35))
                .frame(width: 60, alignment: .leading)

            switch kind {
            case .strength:
                darkDoubleField(weightBinding(set: set, units: units))
                darkIntField(repsBinding(set: set))
            case .bodyweight:
                darkIntField(repsBinding(set: set))
                Spacer().frame(maxWidth: .infinity)
            case .cardio:
                darkIntField(minutesBinding(set: set))
                darkDoubleField(distanceBinding(set: set, units: units))
            }

            Button {
                vm.toggleSetCompleted(exerciseId: exerciseId, setId: set.wrappedValue.id)
                if set.wrappedValue.completed, !rest.isRunning {
                    rest.start()
                }
            } label: {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(completed ? Theme.Colors.limeInk : Color.white.opacity(0.4))
                    .frame(width: 40, height: 36)
                    .background(completed ? Theme.Colors.lime : Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .opacity(completed ? 0.55 : 1.0)
    }

    private func setIndexChip(_ idx: Int, isPR: Bool, completed: Bool) -> some View {
        Text(isPR ? "PR" : "\(idx)")
            .font(Theme.Fonts.display(13))
            .foregroundStyle(isPR ? Theme.Colors.limeInk : .white)
            .frame(width: 36, height: 28)
            .background(isPR ? Theme.Colors.lime : Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func previousText(_ set: WorkoutSet,
                              kind: ExerciseKind,
                              units: UnitsPreference) -> String {
        // Best-effort: without a lift history DB we can only show this session's prior set.
        switch kind {
        case .strength:
            let kg = set.weightKg ?? 0
            let reps = set.reps ?? 0
            if kg == 0 && reps == 0 { return "—" }
            let w = units == .metric ? kg : UnitConversion.lb(fromKg: kg)
            return "\(Int(w))×\(reps)"
        case .bodyweight:
            return set.reps.map { "×\($0)" } ?? "—"
        case .cardio:
            return set.durationSeconds.map { "\($0 / 60)m" } ?? "—"
        }
    }

    private func darkDoubleField(_ binding: Binding<Double>) -> some View {
        TextField("", value: binding, format: .number.precision(.fractionLength(0...2)))
            .keyboardType(.decimalPad)
            .font(Theme.Fonts.display(22))
            .foregroundStyle(.white)
            .tint(Theme.Colors.lime)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func darkIntField(_ binding: Binding<Int>) -> some View {
        TextField("", value: binding, format: .number)
            .keyboardType(.numberPad)
            .font(Theme.Fonts.display(22))
            .foregroundStyle(.white)
            .tint(Theme.Colors.lime)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Add exercise + notes

    private var addExerciseRow: some View {
        Button { showingExercisePicker = true } label: {
            HStack {
                Image(systemName: "plus")
                Text("Add exercise")
                    .font(Theme.Fonts.mono(10))
                    .tracking(1.0)
            }
            .foregroundStyle(Color.white.opacity(0.7))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.m)
                    .strokeBorder(Color.white.opacity(0.18),
                                  style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
            )
        }
        .buttonStyle(.plain)
    }

    private var notesBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            PCEyebrow(text: "Notes", color: Color.white.opacity(0.55))
            TextField("Optional notes", text: $vm.notes, axis: .vertical)
                .font(Theme.Fonts.ui(14))
                .foregroundStyle(.white)
                .tint(Theme.Colors.lime)
                .lineLimit(1...4)
                .padding(12)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
        }
    }

    // MARK: - Bindings (reused from old file)

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
