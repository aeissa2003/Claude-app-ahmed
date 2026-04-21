import SwiftUI

struct OnboardingFlow: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel: OnboardingViewModel
    @State private var step: Step = .welcome
    let onComplete: (UserProfile) -> Void

    enum Step: Int, CaseIterable {
        case welcome, basics, handle, goal, diet, protein
    }

    init(uid: String, seedDisplayName: String, seedEmail: String?, onComplete: @escaping (UserProfile) -> Void) {
        _viewModel = State(initialValue: OnboardingViewModel(
            uid: uid,
            displayName: seedDisplayName,
            email: seedEmail
        ))
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ProgressView(
                    value: Double(step.rawValue + 1),
                    total: Double(Step.allCases.count)
                )
                .padding(.horizontal)

                Group {
                    switch step {
                    case .welcome: WelcomeStep(viewModel: viewModel)
                    case .basics:  BasicsStep(viewModel: viewModel)
                    case .handle:  HandleStep(viewModel: viewModel, repo: env.userProfiles)
                    case .goal:    GoalStep(viewModel: viewModel)
                    case .diet:    DietStep(viewModel: viewModel)
                    case .protein: ProteinGoalStep(viewModel: viewModel)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                footer
            }
            .padding(.top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if step != .welcome {
                        Button("Back") { back() }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if step == .diet {
                        Button("Skip") { next() }
                    }
                }
            }
            .overlay { if viewModel.isSaving { ProgressView().controlSize(.large) } }
            .alert("Couldn’t save profile", isPresented: .constant(viewModel.errorText != nil)) {
                Button("OK") { viewModel.errorText = nil }
            } message: {
                Text(viewModel.errorText ?? "")
            }
        }
    }

    @ViewBuilder private var footer: some View {
        Button(action: primaryAction) {
            Text(primaryTitle)
                .frame(maxWidth: .infinity, minHeight: 50)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!primaryEnabled)
        .padding()
    }

    private var primaryTitle: String {
        step == .protein ? "Finish" : "Continue"
    }

    private var primaryEnabled: Bool {
        switch step {
        case .welcome:  !viewModel.displayName.trimmingCharacters(in: .whitespaces).isEmpty
        case .basics:   viewModel.age > 0 && viewModel.heightCm > 0 && viewModel.weightKg > 0
        case .handle:   viewModel.handleCheckState == .available
        case .goal:     true
        case .diet:     true
        case .protein:  viewModel.proteinGoalG > 0
        }
    }

    private func primaryAction() {
        if step == .protein {
            Task { await finish() }
        } else {
            next()
        }
    }

    private func next() {
        if let nextStep = Step(rawValue: step.rawValue + 1) {
            step = nextStep
            // When reaching the protein step, recompute the default from current bodyweight + goal
            if step == .protein {
                viewModel.proteinGoalG = viewModel.computedProteinGoal
            }
        }
    }

    private func back() {
        if let prev = Step(rawValue: step.rawValue - 1) {
            step = prev
        }
    }

    private func finish() async {
        viewModel.isSaving = true
        defer { viewModel.isSaving = false }
        do {
            try await env.userProfiles.reserveHandle(viewModel.handle, uid: viewModel.uid)
            let profile = viewModel.profileSnapshot()
            try await env.userProfiles.save(profile)
            onComplete(profile)
        } catch {
            viewModel.errorText = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
