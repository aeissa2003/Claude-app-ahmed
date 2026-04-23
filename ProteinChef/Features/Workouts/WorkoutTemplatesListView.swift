import SwiftUI

struct WorkoutTemplatesListView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    /// Tapping "Start this template" in this sheet bubbles the chosen template up so the
    /// parent WorkoutsListView can present ActiveWorkoutView seeded with it.
    let onStart: (WorkoutTemplate) -> Void

    @State private var templates: [WorkoutTemplate] = []
    @State private var showingEditor: WorkoutTemplate?
    @State private var showingNew = false

    var body: some View {
        NavigationStack {
            Group {
                if templates.isEmpty {
                    ContentUnavailableView {
                        Label("No templates", systemImage: "doc.on.doc")
                    } description: {
                        Text("Build a template from scratch, or save one from a finished workout.")
                    } actions: {
                        Button("New template") { showingNew = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(templates) { template in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(template.name).font(.headline)
                                Text(summary(template))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack {
                                    Button {
                                        dismiss()
                                        // Small delay so the sheet dismisses before presenting the next one.
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            onStart(template)
                                        }
                                    } label: {
                                        Label("Start", systemImage: "play.fill")
                                            .font(.caption.bold())
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(Theme.Colors.protein)

                                    Button {
                                        showingEditor = template
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNew = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New template")
                }
            }
            .task(id: env.auth.currentUid ?? "") {
                await subscribe()
            }
            .sheet(isPresented: $showingNew) {
                if let uid = env.auth.currentUid {
                    WorkoutTemplateEditorView(uid: uid).environment(env)
                }
            }
            .sheet(item: $showingEditor) { template in
                WorkoutTemplateEditorView(uid: template.ownerUid, editing: template).environment(env)
            }
        }
    }

    private func summary(_ t: WorkoutTemplate) -> String {
        let count = t.exercises.count
        let setTotal = t.exercises.reduce(0) { $0 + $1.targetSets }
        return "\(count) exercise\(count == 1 ? "" : "s") · \(setTotal) set\(setTotal == 1 ? "" : "s")"
    }

    private func subscribe() async {
        guard let uid = env.auth.currentUid else { return }
        do {
            for try await list in env.workoutTemplates.listStream(ownerUid: uid) {
                templates = list
            }
        } catch {
            templates = []
        }
    }

    private func delete(at offsets: IndexSet) {
        guard let uid = env.auth.currentUid else { return }
        let toDelete = offsets.map { templates[$0] }
        Task {
            for template in toDelete {
                try? await env.workoutTemplates.delete(ownerUid: uid, id: template.id)
            }
        }
    }
}
