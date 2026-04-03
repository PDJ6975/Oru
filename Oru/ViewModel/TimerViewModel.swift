import SwiftUI

@MainActor
@Observable
class TimerViewModel {

    enum TimerState {
        case idle, running
    }

    private(set) var state: TimerState = .idle
    private(set) var timerInterval: ClosedRange<Date>?
    var selectedMinutes = 25

    private var timerTask: Task<Void, Never>?

    static let stepMinutes = 5
    static let minMinutes = 5
    static let maxMinutes = 60

    var canDecrease: Bool { selectedMinutes > Self.minMinutes }
    var canIncrease: Bool { selectedMinutes < Self.maxMinutes }

    func start() {
        let now = Date.now
        let end = now.addingTimeInterval(Double(selectedMinutes * 60))
        timerInterval = now...end
        state = .running

        timerTask = Task {
            try? await Task.sleep(for: .seconds(selectedMinutes * 60))
            guard !Task.isCancelled else { return }
            finish()
        }
    }

    func cancel() {
        timerTask?.cancel()
        timerTask = nil
        timerInterval = nil
        state = .idle
    }

    private func finish() {
        timerTask = nil
        timerInterval = nil
        state = .idle
    }
}
