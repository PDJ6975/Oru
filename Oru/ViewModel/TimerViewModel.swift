import ActivityKit
import os
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

    var onSessionCompleted: ((Int) -> Void)?
    private let repository: HabitRepositoryProtocol
    private let habitVM: HabitViewModel
    private var timerTask: Task<Void, Never>?
    private var currentActivity: Activity<OruTimerAttributes>?
    private var widgetCancelObserver: Any?

    static let stepMinutes = 5
    static let minMinutes = 5
    static let maxMinutes = 60

    var canDecrease: Bool { selectedMinutes > Self.minMinutes }
    var canIncrease: Bool { selectedMinutes < Self.maxMinutes }

    private static let logger = Logger(subsystem: "com.antoniorodriguez.Oru2026", category: "LiveActivity")

    init(repository: HabitRepositoryProtocol, habitVM: HabitViewModel) {
        self.repository = repository
        self.habitVM = habitVM
        widgetCancelObserver = NotificationCenter.default.addObserver(
            forName: .timerCancelledFromWidget,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.timerTask?.cancel() // cancel de Swift para interrumpir el Sleep
                self.resetSession()
            }
        }
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
        startLiveActivity(endDate: end)
        savePendingSession(startDate: now, endDate: end)
        scheduleFinish(after: Double(selectedMinutes * 60))
    }

    func cancel() {
        timerTask?.cancel()
        endLiveActivity(dismissImmediately: true)
        resetSession()
    }

    private func finish() {
        endLiveActivity(dismissImmediately: false)
        if trackHabit, let habit = selectedHabit {
            recordSession(for: habit)
            onSessionCompleted?(selectedMinutes)
        }
        resetSession()
    }

    private func scheduleFinish(after seconds: TimeInterval) {
        timerTask = Task {
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            finish()
        }
    }

    private func resetSession() {
        timerTask = nil
        timerInterval = nil
        state = .idle
        UIApplication.shared.isIdleTimerDisabled = false
        PendingSessionStore.clear()
    }

    // MARK: - Live Activity

    private func startLiveActivity(endDate: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        // Limpiar actividades residuales (ej. sesión anterior aún visible)
        for activity in Activity<OruTimerAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }

        let attributes = OruTimerAttributes(
            habitName: trackHabit ? selectedHabit?.name : nil,
            habitIcon: trackHabit ? selectedHabit?.icon : nil,
            totalMinutes: selectedMinutes
        )
        let contentState = OruTimerAttributes.ContentState(endDate: endDate)
        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: endDate)
            )
        } catch {
            Self.logger.warning("No se pudo iniciar la Live Activity: \(error.localizedDescription)")
        }
    }

    private func endLiveActivity(dismissImmediately: Bool) {
        guard let activity = currentActivity else { return }
        let finalState = OruTimerAttributes.ContentState(endDate: .now)
        let policy: ActivityUIDismissalPolicy = dismissImmediately
            ? .immediate
            : .after(.now + 180)
        Task {
            await activity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: policy)
        }
        currentActivity = nil
    }

    // MARK: - Persistencia

    private func savePendingSession(startDate: Date, endDate: Date) {
        PendingSessionStore.save(PendingSessionStore.Session(
            startDate: startDate,
            endDate: endDate,
            selectedMinutes: selectedMinutes,
            habitName: trackHabit ? selectedHabit?.name : nil,
            trackHabit: trackHabit
        ))
    }

    func recoverSessionIfNeeded() {
        guard state == .idle, let pending = PendingSessionStore.load() else { return }

        let now = Date.now

        if pending.endDate > now {
            timerInterval = pending.startDate...pending.endDate
            selectedMinutes = pending.selectedMinutes
            state = .running
            UIApplication.shared.isIdleTimerDisabled = true
            currentActivity = Activity<OruTimerAttributes>.activities.first

            let remaining = pending.endDate.timeIntervalSince(now)
            scheduleFinish(after: remaining)
        } else {
            if pending.trackHabit, let habitName = pending.habitName {
                selectedMinutes = pending.selectedMinutes
                let habit = compatibleHabits.first(where: { $0.name == habitName })
                    ?? (try? repository.fetchActiveHabits())?.first(where: { $0.name == habitName })
                if let habit {
                    recordSession(for: habit)
                    onSessionCompleted?(pending.selectedMinutes)
                }
            }
            for activity in Activity<OruTimerAttributes>.activities {
                Task { await activity.end(nil, dismissalPolicy: .immediate) }
            }
            PendingSessionStore.clear()
        }
    }

    // MARK: - Registro

    func recordSession(for habit: Habit) {
        let sessionMinutes = Double(selectedMinutes)
        let amount = habit.unit?.name == "h" ? sessionMinutes / 60.0 : sessionMinutes
        let existing = habitVM.todayCompliance(for: habit)?.recordedAmount ?? 0
        habitVM.recordAmount(existing + amount, for: habit)
    }
}
