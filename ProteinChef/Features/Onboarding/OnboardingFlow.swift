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
        ZStack(alignment: .bottom) {
            Theme.Colors.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                header
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
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            footer
        }
        .overlay { if viewModel.isSaving { ProgressView().controlSize(.large) } }
        .alert("Couldn’t save profile", isPresented: .constant(viewModel.errorText != nil)) {
            Button("OK") { viewModel.errorText = nil }
        } message: {
            Text(viewModel.errorText ?? "")
        }
    }

    // MARK: - Header (back + progress segments + skip)

    private var header: some View {
        HStack(spacing: 10) {
            if step != .welcome {
                PCIconButton(systemName: "chevron.left", variant: .paper) { back() }
            } else {
                Spacer().frame(width: 40)
            }
            PCSegmentProgress(total: Step.allCases.count,
                              current: step.rawValue + 1)
                .frame(maxWidth: .infinity)
            if step == .diet {
                Button("SKIP") { next() }
                    .font(Theme.Fonts.mono(10, weight: .semibold))
                    .tracking(1.0)
                    .foregroundStyle(Theme.Colors.ink3)
                    .frame(width: 52, alignment: .trailing)
            } else {
                Spacer().frame(width: 52)
            }
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.top, Theme.Spacing.s)
        .padding(.bottom, Theme.Spacing.md)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 0) {
            PCButton(title: primaryTitle,
                     systemImage: step == .protein ? "checkmark" : "arrow.right",
                     style: primaryEnabled ? .indigo : .ghost) {
                primaryAction()
            }
            .disabled(!primaryEnabled)
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.top, Theme.Spacing.s)
            .padding(.bottom, Theme.Spacing.l)
        }
        .background(
            Theme.Colors.bg.opacity(0.96)
                .background(.ultraThinMaterial)
                .overlay(Divider().overlay(Theme.Colors.line), alignment: .top)
        )
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
