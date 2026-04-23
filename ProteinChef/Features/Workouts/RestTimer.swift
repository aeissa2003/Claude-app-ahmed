import Foundation
import Observation

@Observable
@MainActor
final class RestTimer {
    var isRunning: Bool = false
    var remainingSeconds: Int = 0
    var presetSeconds: Int = 90

    private var task: Task<Void, Never>?

    func start(_ seconds: Int? = nil) {
        stop()
        remainingSeconds = seconds ?? presetSeconds
        isRunning = true
        task = Task { [weak self] in
            while true {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                guard let self else { return }
                guard self.isRunning else { return }
                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                } else {
                    self.isRunning = false
                    return
                }
            }
        }
    }

    func stop() {
        isRunning = false
        task?.cancel()
        task = nil
    }

    func adjust(by delta: Int) {
        if isRunning {
            remainingSeconds = max(0, remainingSeconds + delta)
        } else {
            presetSeconds = max(15, presetSeconds + delta)
        }
    }

    var displayText: String {
        let s = isRunning ? remainingSeconds : presetSeconds
        let mm = s / 60
        let ss = s % 60
        return String(format: "%d:%02d", mm, ss)
    }
}
