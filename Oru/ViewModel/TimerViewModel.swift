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

    var trackHabit = false
    var selectedHabit: Habit?
    private(set) var compatibleHabits: [Habit] = []

    var lastError: String?
    private let repository: HabitRepositoryProtocol
    private var timerTask: Task<Void, Never>?

    static let stepMinutes = 5
    static let minMinutes = 5
    static let maxMinutes = 60

    var canDecrease: Bool { selectedMinutes > Self.minMinutes }
    var canIncrease: Bool { selectedMinutes < Self.maxMinutes }

    init(repository: HabitRepositoryProtocol) {
        self.repository = repository
    }

    func loadCompatibleHabits() {
        do {
            let active = try repository.fetchActiveHabits()
            compatibleHabits = active.filter { $0.type == .quantity && ($0.unit?.isTimeUnit ?? false) }
        } catch {
            compatibleHabits = []
        }
    }

    func start() {
        let now = Date.now
        let end = now.addingTimeInterval(Double(selectedMinutes * 60))
        timerInterval = now...end
        state = .running
        UIApplication.shared.isIdleTimerDisabled = true

        timerTask = Task {
            try? await Task.sleep(for: .seconds(selectedMinutes * 60))
            guard !Task.isCancelled else { return }
            finish()
        }
    }

    func cancel() {
        timerTask?.cancel()
        resetSession()
    }

    private func finish() {
        if trackHabit, let habit = selectedHabit {
            recordSession(for: habit)
        }
        resetSession()
    }

    private func resetSession() {
        timerTask = nil
        timerInterval = nil
        state = .idle
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func recordSession(for habit: Habit) {
        let sessionMinutes = Double(selectedMinutes)
        let amount = habit.unit?.name == "h" ? sessionMinutes / 60.0 : sessionMinutes

        let todayCompliance = habit.compliances.first {
            Calendar.current.isDateInToday($0.date)
        }

        if let compliance = todayCompliance {
            let accumulated = (compliance.recordedAmount ?? 0) + amount
            compliance.recordedAmount = accumulated
            compliance.completed = habit.isGoalMet(accumulated)
        } else {
            let completed = habit.isGoalMet(amount)
            let compliance = Compliance(date: .now, completed: completed, recordedAmount: amount)
            habit.compliances.append(compliance)
        }

        habit.updateConsolidationStatus()

        do {
            try repository.saveChanges()
        } catch {
            lastError = "No se pudo registrar la sesión: \(error.localizedDescription)"
        }
    }
}
