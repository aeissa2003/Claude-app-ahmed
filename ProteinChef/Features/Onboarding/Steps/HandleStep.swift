import SwiftUI

struct HandleStep: View {
    @Bindable var viewModel: OnboardingViewModel
    let repo: UserProfileRepositoryProtocol

    @State private var checkTask: Task<Void, Never>?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("STEP 3 OF 6")
                    .font(Theme.Fonts.mono(10, weight: .semibold))
                    .tracking(1.0)
                    .foregroundStyle(Theme.Colors.indigo)

                Text("Pick a\nhandle.")
                    .font(Theme.Fonts.display(34))
                    .tracking(-1.0)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Your handle is how friends find you. Lowercase letters, numbers, and underscores — 3 to 20 characters.")
                    .font(Theme.Fonts.ui(14))
                    .foregroundStyle(Theme.Colors.ink3)

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Text("@")
                            .font(Theme.Fonts.display(24))
                            .foregroundStyle(Theme.Colors.ink3)
                        TextField("handle", text: $viewModel.handle)
                            .font(Theme.Fonts.display(24))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textContentType(.username)
                            .onChange(of: viewModel.handle) { _, newValue in
                                scheduleCheck(newValue)
                            }
                    }
                    Rectangle().fill(Theme.Colors.line2).frame(height: 1)
                    statusRow
                }
                .padding(.top, Theme.Spacing.s)
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.bottom, 120)
        }
    }

    @ViewBuilder private var statusRow: some View {
        switch viewModel.handleCheckState {
        case .idle:
            Text("3–20 letters, numbers, or underscores. Must start with a letter.")
                .font(Theme.Fonts.ui(12))
                .foregroundStyle(Theme.Colors.ink3)
        case .checking:
            statusLabel("Checking…", systemImage: "hourglass", color: Theme.Colors.ink3)
        case .invalid:
            statusLabel("Handle format is invalid.", systemImage: "exclamationmark.triangle.fill", color: .orange)
        case .taken:
            statusLabel("That handle is already taken.", systemImage: "xmark.circle.fill", color: .red)
        case .available:
            statusLabel("Available.", systemImage: "checkmark.circle.fill", color: Theme.Colors.protein)
        case .failed(let message):
            statusLabel(message, systemImage: "wifi.exclamationmark", color: .red)
        }
    }

    private func statusLabel(_ text: String, systemImage: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage).font(.system(size: 12))
            Text(text).font(Theme.Fonts.ui(13, weight: .medium))
        }
        .foregroundStyle(color)
    }

    private func scheduleCheck(_ raw: String) {
        checkTask?.cancel()
        let trimmed = HandleValidator.normalize(raw)
        if trimmed.isEmpty {
            viewModel.handleCheckState = .idle
            return
        }
        guard HandleValidator.isValid(trimmed) else {
            viewModel.handleCheckState = .invalid
            return
        }
        viewModel.handleCheckState = .checking
        checkTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            if Task.isCancelled { return }
            do {
                let available = try await repo.isHandleAvailable(trimmed)
                if Task.isCancelled { return }
                await MainActor.run {
                    viewModel.handleCheckState = available ? .available : .taken
                }
            } catch {
                await MainActor.run {
                    viewModel.handleCheckState = .failed(error.localizedDescription)
                }
            }
        }
    }
}
