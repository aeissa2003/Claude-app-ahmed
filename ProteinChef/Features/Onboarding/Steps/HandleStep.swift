import SwiftUI

struct HandleStep: View {
    @Bindable var viewModel: OnboardingViewModel
    let repo: UserProfileRepositoryProtocol

    @State private var checkTask: Task<Void, Never>?

    var body: some View {
        Form {
            Section("Pick a handle") {
                HStack {
                    Text("@").foregroundStyle(.secondary)
                    TextField("handle", text: $viewModel.handle)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.username)
                        .onChange(of: viewModel.handle) { _, newValue in
                            scheduleCheck(newValue)
                        }
                }
                statusRow
            }
        }
    }

    @ViewBuilder private var statusRow: some View {
        switch viewModel.handleCheckState {
        case .idle:
            Text("3–20 letters, numbers, or underscores. Must start with a letter.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        case .checking:
            Label("Checking…", systemImage: "hourglass")
                .font(.footnote).foregroundStyle(.secondary)
        case .invalid:
            Label("Handle format is invalid.", systemImage: "exclamationmark.triangle")
                .font(.footnote).foregroundStyle(.orange)
        case .taken:
            Label("That handle is already taken.", systemImage: "xmark.circle")
                .font(.footnote).foregroundStyle(.red)
        case .available:
            Label("Available!", systemImage: "checkmark.circle.fill")
                .font(.footnote).foregroundStyle(.green)
        }
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
                await MainActor.run { viewModel.handleCheckState = .invalid }
            }
        }
    }
}
