import Foundation
import Observation

@Observable
final class WorkoutEditorViewModel {
    let uid: String
    let editing: Workout?

    var startedAt: Date
    var endedAt: Date?
    var exercises: [WorkoutExercise]
    var notes: String
    var templateId: String?
    var templateName: String?

    var isSaving: Bool = false
    var errorText: String?

    init(uid: String, editing: Workout? = nil, seedTemplate: WorkoutTemplate? = nil) {
        self.uid = uid
        self.editing = editing
        if let workout = editing {
            self.startedAt = workout.startedAt
            self.endedAt = workout.endedAt
            self.exercises = workout.exercises
            self.notes = workout.notes ?? ""
            self.templateId = workout.templateId
            self.templateName = workout.templateName
        } else if let template = seedTemplate {
            self.startedAt = Date()
            self.endedAt = nil
            self.notes = ""
            self.templateId = template.id
            self.templateName = template.name
            self.exercises = template.exercises.map { tex in
                WorkoutExercise(
                    id: UUID().uuidString,
                    exerciseId: tex.exerciseId,
                    exerciseName: tex.exerciseName,
                    isCustom: tex.isCustom,
                    kind: tex.kind,
                    order: tex.order,
                    sets: (0..<tex.targetSets).map { i in
                        WorkoutSet(
                            id: UUID().uuidString,
                            order: i,
                            weightKg: tex.kind == .strength ? 0 : nil,
                            reps: tex.targetReps,
                            durationSeconds: tex.kind == .cardio ? tex.targetDurationSeconds : nil,
                            distanceM: nil,
                            completed: false
                        )
                    },
                    notes: nil
                )
            }
        } else {
            self.startedAt = Date()
            self.endedAt = nil
            self.exercises = []
            self.notes = ""
            self.templateId = nil
            self.templateName = nil
        }
    }

    var isValid: Bool {
        !exercises.isEmpty
    }

    // MARK: - Exercise mutations

    func addExercise(_ picked: PickedExercise) {
        let newExercise = WorkoutExercise(
            id: UUID().uuidString,
            exerciseId: picked.exerciseId,
            exerciseName: picked.name,
            isCustom: picked.isCustom,
            kind: picked.kind,
            order: exercises.count,
            sets: [defaultSet(for: picked.kind, order: 0)],
            notes: nil
        )
        exercises.append(newExercise)
    }

    func removeExercise(at offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
        for (i, _) in exercises.enumerated() { exercises[i].order = i }
    }

    func addSet(toExercise exerciseId: String) {
        guard let idx = exercises.firstIndex(where: { $0.id == exerciseId }) else { return }
        let order = exercises[idx].sets.count
        let newSet: WorkoutSet
        if let last = exercises[idx].sets.last {
            // Copy the previous set's values so the user only tweaks what's different.
            newSet = WorkoutSet(
                id: UUID().uuidString,
                order: order,
                weightKg: last.weightKg,
                reps: last.reps,
                durationSeconds: last.durationSeconds,
                distanceM: last.distanceM,
                completed: false
            )
        } else {
            newSet = defaultSet(for: exercises[idx].kind, order: order)
        }
        exercises[idx].sets.append(newSet)
    }

    func removeSet(fromExercise exerciseId: String, at offsets: IndexSet) {
        guard let idx = exercises.firstIndex(where: { $0.id == exerciseId }) else { return }
        exercises[idx].sets.remove(atOffsets: offsets)
        for (i, _) in exercises[idx].sets.enumerated() { exercises[idx].sets[i].order = i }
    }

    func toggleSetCompleted(exerciseId: String, setId: String) {
        guard let eIdx = exercises.firstIndex(where: { $0.id == exerciseId }),
              let sIdx = exercises[eIdx].sets.firstIndex(where: { $0.id == setId }) else { return }
        exercises[eIdx].sets[sIdx].completed.toggle()
    }

    private func defaultSet(for kind: ExerciseKind, order: Int) -> WorkoutSet {
        switch kind {
        case .strength:
            return WorkoutSet(id: UUID().uuidString, order: order, weightKg: 0, reps: 5, durationSeconds: nil, distanceM: nil, completed: false)
        case .bodyweight:
            return WorkoutSet(id: UUID().uuidString, order: order, weightKg: nil, reps: 10, durationSeconds: nil, distanceM: nil, completed: false)
        case .cardio:
            return WorkoutSet(id: UUID().uuidString, order: order, weightKg: nil, reps: nil, durationSeconds: 600, distanceM: nil, completed: false)
        }
    }

    // MARK: - Snapshot

    func snapshot() -> Workout {
        let now = Date()
        return Workout(
            id: editing?.id ?? UUID().uuidString,
            ownerUid: uid,
            startedAt: startedAt,
            endedAt: endedAt,
            templateId: templateId,
            templateName: templateName,
            exercises: exercises,
            notes: notes.isEmpty ? nil : notes,
            createdAt: editing?.createdAt ?? now,
            updatedAt: now
        )
    }
}
