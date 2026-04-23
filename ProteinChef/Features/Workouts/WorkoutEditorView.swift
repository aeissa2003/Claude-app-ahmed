import SwiftUI

/// Unified post-hoc workout logger. Also used to edit a completed workout.
struct WorkoutEditorView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.userProfile) private var profile
    @Environment(\.dismiss) private var dismiss

    @State private var vm: WorkoutEditorViewModel
    @State private var showingExercisePicker = false
    @State private var showingSaveAsTemplate = false
    @State private var templateName: String = ""

    init(uid: String, editing: Workout? = nil, seedTemplate: WorkoutTemplate? = nil) {
        _vm = State(initialValue: WorkoutEditorViewModel(uid: uid, editing: editing, seedTemplate: seedTemplate))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Session") {
                    DatePicker("Started", selection: $vm.startedAt, displayedComponents: [.date, .hourAndMinute])
                    if let ended = vm.endedAt {
                        HStack {
                            DatePicker("Ended", selection: Binding(get: { ended }, set: { vm.endedAt = $0 }), displayedComponents: [.date, .hourAndMinute])
                            Button {
                                vm.endedAt = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        Button {
                            vm.endedAt = Date()
                        } label: {
                            Label("Set end time", systemImage: "stopwatch")
                        }
                    }
                }

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
            .navigationTitle(vm.editing == nil ? "Log workout" : "Edit workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            Task { await save() }
                        } label: {
                            Label("Save", systemImage: "checkmark")
                        }
                        .disabled(!vm.isValid || vm.isSaving)

                        if vm.isValid {
                            Button {
                                showingSaveAsTemplate = true
                            } label: {
                                Label("Save as template", systemImage: "doc.on.doc")
                            }
                        }
                    } label: {
                        if vm.isSaving {
                            ProgressView()
                        } else {
                            Text("Save").fontWeight(.semibold)
                        }
                    }
                    .disabled(!vm.isValid || vm.isSaving)
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView { picked in
                    vm.addExercise(picked)
                }
                .environment(env)
            }
            .alert("Save as template", isPresented: $showingSaveAsTemplate) {
                TextField("Template name", text: $templateName)
                Button("Save") {
                    Task { await saveAsTemplate() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Save this workout's exercises and rep scheme as a reusable template.")
            }
            .alert("Couldn’t save", isPresented: .constant(vm.errorText != nil)) {
                Button("OK") { vm.errorText = nil }
            } message: {
                Text(vm.errorText ?? "")
            }
        }
    }

    // MARK: - Exercise section

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

            setsTableHeader(kind: exercise.wrappedValue.kind, units: units)
            ForEach(exercise.sets) { $set in
                setRow(set: $set, kind: exercise.wrappedValue.kind, units: units, exerciseId: exercise.wrappedValue.id)
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

    private func setsTableHeader(kind: ExerciseKind, units: UnitsPreference) -> some View {
        HStack(spacing: 0) {
            Text("#")
                .frame(width: 24, alignment: .leading)
            switch kind {
            case .strength:
                Text(units == .metric ? "kg" : "lb").frame(width: 80, alignment: .leading)
                Text("reps").frame(width: 70, alignment: .leading)
            case .bodyweight:
                Text("reps").frame(width: 80, alignment: .leading)
            case .cardio:
                Text("min").frame(width: 70, alignment: .leading)
                Text(units == .metric ? "km" : "mi").frame(width: 70, alignment: .leading)
            }
            Spacer()
            Image(systemName: "checkmark").foregroundStyle(.secondary)
        }
        .font(.caption.bold())
        .foregroundStyle(.secondary)
    }

    private func setRow(
        set: Binding<WorkoutSet>,
        kind: ExerciseKind,
        units: UnitsPreference,
        exerciseId: String
    ) -> some View {
        HStack(spacing: 0) {
            Text("\(set.wrappedValue.order + 1)")
                .frame(width: 24, alignment: .leading)
                .foregroundStyle(.secondary)
                .font(.footnote)

            switch kind {
            case .strength:
                weightField(set: set, units: units).frame(width: 80, alignment: .leading)
                intField(value: Binding(
                    get: { set.wrappedValue.reps ?? 0 },
                    set: { set.wrappedValue.reps = $0 }
                )).frame(width: 70, alignment: .leading)
            case .bodyweight:
                intField(value: Binding(
                    get: { set.wrappedValue.reps ?? 0 },
                    set: { set.wrappedValue.reps = $0 }
                )).frame(width: 80, alignment: .leading)
            case .cardio:
                intField(value: Binding(
                    get: { (set.wrappedValue.durationSeconds ?? 0) / 60 },
                    set: { set.wrappedValue.durationSeconds = $0 * 60 }
                )).frame(width: 70, alignment: .leading)
                distanceField(set: set, units: units).frame(width: 70, alignment: .leading)
            }

            Spacer()

            Button {
                vm.toggleSetCompleted(exerciseId: exerciseId, setId: set.wrappedValue.id)
            } label: {
                Image(systemName: set.wrappedValue.completed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(set.wrappedValue.completed ? Theme.Colors.protein : .secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private func weightField(set: Binding<WorkoutSet>, units: UnitsPreference) -> some View {
        TextField("0", value: Binding(
            get: {
                let kg = set.wrappedValue.weightKg ?? 0
                return units == .metric ? kg : UnitConversion.lb(fromKg: kg)
            },
            set: { newVal in
                set.wrappedValue.weightKg = units == .metric ? newVal : UnitConversion.kg(fromLb: newVal)
            }
        ), format: .number)
        .keyboardType(.decimalPad)
        .textFieldStyle(.roundedBorder)
    }

    private func intField(value: Binding<Int>) -> some View {
        TextField("0", value: value, format: .number)
            .keyboardType(.numberPad)
            .textFieldStyle(.roundedBorder)
    }

    private func distanceField(set: Binding<WorkoutSet>, units: UnitsPreference) -> some View {
        TextField("0", value: Binding(
            get: {
                let m = set.wrappedValue.distanceM ?? 0
                return units == .metric ? m / 1000 : m / 1609.344
            },
            set: { newVal in
                set.wrappedValue.distanceM = units == .metric ? newVal * 1000 : newVal * 1609.344
            }
        ), format: .number)
        .keyboardType(.decimalPad)
        .textFieldStyle(.roundedBorder)
    }

    // MARK: - Actions

    private func save() async {
        vm.isSaving = true
        defer { vm.isSaving = false }
        do {
            try await env.workouts.save(vm.snapshot())
            dismiss()
        } catch {
            vm.errorText = error.localizedDescription
        }
    }

    private func saveAsTemplate() async {
        let trimmed = templateName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let now = Date()
        let template = WorkoutTemplate(
            id: UUID().uuidString,
            ownerUid: vm.uid,
            name: trimmed,
            exercises: vm.exercises.enumerated().map { (i, ex) in
                WorkoutTemplateExercise(
                    id: UUID().uuidString,
                    exerciseId: ex.exerciseId,
                    exerciseName: ex.exerciseName,
                    isCustom: ex.isCustom,
                    kind: ex.kind,
                    order: i,
                    targetSets: max(ex.sets.count, 1),
                    targetReps: ex.kind == .cardio ? nil : (ex.sets.last?.reps ?? 10),
                    targetDurationSeconds: ex.kind == .cardio ? (ex.sets.last?.durationSeconds ?? 600) : nil
                )
            },
            createdAt: now,
            updatedAt: now
        )
        do {
            try await env.workoutTemplates.save(template)
            templateName = ""
        } catch {
            vm.errorText = error.localizedDescription
        }
    }
}
