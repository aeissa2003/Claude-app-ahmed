import SwiftUI

/// Result of picking an exercise: enough info to build a `WorkoutExercise` or `WorkoutTemplateExercise`.
struct PickedExercise: Hashable {
    let exerciseId: String
    let name: String
    let isCustom: Bool
    let kind: ExerciseKind
}

struct ExercisePickerView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    let onPick: (PickedExercise) -> Void

    @State private var query: String = ""
    @State private var customs: [CustomExercise] = []
    @State private var showingCustomForm = false

    var body: some View {
        NavigationStack {
            List {
                if !customs.isEmpty {
                    Section("Your custom exercises") {
                        ForEach(filteredCustoms) { ex in
                            Button {
                                pick(custom: ex)
                            } label: {
                                exerciseRow(
                                    name: ex.name,
                                    subtitle: "Custom · \(ex.primaryMuscle.rawValue)",
                                    kind: ex.resolvedKind
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Catalog") {
                    if filteredCatalog.isEmpty && !query.isEmpty {
                        Button {
                            showingCustomForm = true
                        } label: {
                            Label("Create custom “\(query)”", systemImage: "plus.circle")
                        }
                    } else {
                        ForEach(filteredCatalog) { ex in
                            Button {
                                pick(catalog: ex)
                            } label: {
                                exerciseRow(
                                    name: ex.name,
                                    subtitle: "\(ex.primaryMuscle.rawValue) · \(ex.equipment.rawValue)",
                                    kind: ex.resolvedKind
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .searchable(text: $query, prompt: "Search exercises")
            .navigationTitle("Pick exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCustomForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Create custom exercise")
                }
            }
            .task { await loadCustoms() }
            .sheet(isPresented: $showingCustomForm) {
                CustomExerciseForm(seedName: query) { new in
                    Task {
                        do {
                            guard let uid = env.auth.currentUid else { return }
                            try await env.customExercises.save(ownerUid: uid, new)
                            customs.append(new)
                            pick(custom: new)
                        } catch {
                            // swallow for v1 — form stays open
                        }
                    }
                }
            }
        }
    }

    private var filteredCatalog: [Exercise] {
        env.exerciseCatalog.search(query, limit: 50)
    }

    private var filteredCustoms: [CustomExercise] {
        guard !query.isEmpty else { return customs }
        let q = query.lowercased()
        return customs.filter { $0.name.lowercased().contains(q) }
    }

    private func exerciseRow(name: String, subtitle: String, kind: ExerciseKind) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name).foregroundStyle(.primary)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            kindBadge(kind)
        }
    }

    @ViewBuilder private func kindBadge(_ kind: ExerciseKind) -> some View {
        let (text, color): (String, Color) = {
            switch kind {
            case .strength:   ("Weight", Theme.Colors.protein)
            case .bodyweight: ("Reps",   Theme.Colors.carbs)
            case .cardio:     ("Cardio", Theme.Colors.kcal)
            }
        }()
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func pick(catalog: Exercise) {
        onPick(PickedExercise(
            exerciseId: catalog.id,
            name: catalog.name,
            isCustom: false,
            kind: catalog.resolvedKind
        ))
        dismiss()
    }

    private func pick(custom: CustomExercise) {
        onPick(PickedExercise(
            exerciseId: custom.id,
            name: custom.name,
            isCustom: true,
            kind: custom.resolvedKind
        ))
        dismiss()
    }

    private func loadCustoms() async {
        guard let uid = env.auth.currentUid else { return }
        customs = (try? await env.customExercises.list(ownerUid: uid)) ?? []
    }
}

private struct CustomExerciseForm: View {
    @Environment(\.dismiss) private var dismiss

    let seedName: String
    let onSave: (CustomExercise) -> Void

    @State private var name: String = ""
    @State private var muscle: MuscleGroup = .chest
    @State private var equipment: Equipment = .other
    @State private var kind: ExerciseKind = .strength

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    TextField("Name", text: $name)
                    Picker("Primary muscle", selection: $muscle) {
                        ForEach(MuscleGroup.allCases, id: \.self) { m in
                            Text(m.rawValue.capitalized).tag(m)
                        }
                    }
                    Picker("Equipment", selection: $equipment) {
                        ForEach(Equipment.allCases, id: \.self) { e in
                            Text(e.rawValue.capitalized).tag(e)
                        }
                    }
                    Picker("Type", selection: $kind) {
                        ForEach(ExerciseKind.allCases, id: \.self) { k in
                            Text(k.rawValue.capitalized).tag(k)
                        }
                    }
                }
            }
            .navigationTitle("New custom exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let new = CustomExercise(
                            id: UUID().uuidString,
                            name: name.trimmingCharacters(in: .whitespaces),
                            primaryMuscle: muscle,
                            secondaryMuscles: [],
                            equipment: equipment,
                            kind: kind,
                            createdAt: Date()
                        )
                        onSave(new)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if name.isEmpty { name = seedName }
            }
        }
    }
}
