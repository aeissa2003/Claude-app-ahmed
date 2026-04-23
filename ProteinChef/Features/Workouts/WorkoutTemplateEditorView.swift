import SwiftUI

struct WorkoutTemplateEditorView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    let uid: String
    let editing: WorkoutTemplate?

    @State private var name: String
    @State private var exercises: [WorkoutTemplateExercise]
    @State private var showingPicker = false
    @State private var isSaving = false
    @State private var errorText: String?

    init(uid: String, editing: WorkoutTemplate? = nil) {
        self.uid = uid
        self.editing = editing
        _name = State(initialValue: editing?.name ?? "")
        _exercises = State(initialValue: editing?.exercises ?? [])
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !exercises.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Template") {
                    TextField("Name", text: $name)
                }

                ForEach(Array(exercises.enumerated()), id: \.element.id) { idx, exercise in
                    Section {
                        HStack {
                            Text(exercise.exerciseName).font(.headline)
                            Spacer()
                            Button(role: .destructive) {
                                exercises.remove(at: idx)
                            } label: { Image(systemName: "trash").font(.caption) }
                                .buttonStyle(.plain)
                                .foregroundStyle(.red.opacity(0.8))
                        }
                        Stepper(value: $exercises[idx].targetSets, in: 1...10) {
                            HStack { Text("Sets"); Spacer(); Text("\(exercise.targetSets)") }
                        }
                        switch exercise.kind {
                        case .strength, .bodyweight:
                            Stepper(value: Binding(
                                get: { exercises[idx].targetReps ?? 10 },
                                set: { exercises[idx].targetReps = $0 }
                            ), in: 1...50) {
                                HStack { Text("Reps"); Spacer(); Text("\(exercise.targetReps ?? 10)") }
                            }
                        case .cardio:
                            Stepper(value: Binding(
                                get: { (exercises[idx].targetDurationSeconds ?? 600) / 60 },
                                set: { exercises[idx].targetDurationSeconds = $0 * 60 }
                            ), in: 1...180, step: 1) {
                                HStack { Text("Minutes"); Spacer(); Text("\((exercise.targetDurationSeconds ?? 600) / 60)") }
                            }
                        }
                    }
                }

                Section {
                    Button {
                        showingPicker = true
                    } label: {
                        Label("Add exercise", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle(editing == nil ? "New template" : "Edit template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(!isValid || isSaving)
                }
            }
            .sheet(isPresented: $showingPicker) {
                ExercisePickerView { picked in
                    let new = WorkoutTemplateExercise(
                        id: UUID().uuidString,
                        exerciseId: picked.exerciseId,
                        exerciseName: picked.name,
                        isCustom: picked.isCustom,
                        kind: picked.kind,
                        order: exercises.count,
                        targetSets: 3,
                        targetReps: picked.kind == .cardio ? nil : 10,
                        targetDurationSeconds: picked.kind == .cardio ? 600 : nil
                    )
                    exercises.append(new)
                }
                .environment(env)
            }
            .alert("Couldn’t save", isPresented: .constant(errorText != nil)) {
                Button("OK") { errorText = nil }
            } message: { Text(errorText ?? "") }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        let now = Date()
        let template = WorkoutTemplate(
            id: editing?.id ?? UUID().uuidString,
            ownerUid: uid,
            name: name.trimmingCharacters(in: .whitespaces),
            exercises: exercises.enumerated().map { (i, e) in
                var copy = e
                copy.order = i
                return copy
            },
            createdAt: editing?.createdAt ?? now,
            updatedAt: now
        )
        do {
            try await env.workoutTemplates.save(template)
            dismiss()
        } catch {
            errorText = error.localizedDescription
        }
    }
}
