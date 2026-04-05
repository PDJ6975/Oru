import Testing
import Foundation
@testable import Oru

@MainActor
@Suite(.serialized)
struct TimerTests {

    private let timerVM: TimerViewModel
    private let habitVM: HabitViewModel
    private let repo: MockHabitRepository

    init() {
        repo = MockHabitRepository()
        habitVM = HabitViewModel(repository: repo)
        timerVM = TimerViewModel(repository: repo, habitVM: habitVM)
    }

    // MARK: - Helpers

    private func makeQuantityHabit(
        unitName: String = "min",
        dailyGoal: Double? = nil,
        status: Habit.HabitStatus = .active
    ) -> Habit {
        let unit = Oru.Unit(name: unitName, origin: .base)
        let habit = Habit(
            icon: "🧪", name: "Hábito \(unitName)",
            type: .quantity,
            scheduledDays: Habit.Weekday.allCases,
            dailyGoal: dailyGoal,
            status: status
        )
        habit.unit = unit
        return habit
    }

    // MARK: - Filtro de hábitos compatibles

    @Test func loadCompatibleHabits_onlyQuantityTimeUnitActive() {
        let boolHabit = Habit(
            icon: "🧪", name: "Booleano",
            type: .boolean,
            scheduledDays: Habit.Weekday.allCases
        )
        let nonTimeHabit = makeQuantityHabit(unitName: "km")
        let timeHabit = makeQuantityHabit(unitName: "min")
        let archivedTimeHabit = makeQuantityHabit(unitName: "min", status: .archived)
        repo.habits.append(contentsOf: [boolHabit, nonTimeHabit, timeHabit, archivedTimeHabit])

        timerVM.loadCompatibleHabits()

        #expect(timerVM.compatibleHabits.count == 1)
        #expect(timerVM.compatibleHabits.first === timeHabit)
    }

    // MARK: - Registro con unidad "h" (min ya cubierto)

    @Test func recordSession_hourUnit_convertsToFraction() {
        let habit = makeQuantityHabit(unitName: "h")
        timerVM.selectedMinutes = 30

        timerVM.recordSession(for: habit)

        #expect(habitVM.todayCompliance(for: habit)?.recordedAmount == 0.5)
    }

    // MARK: - Acumulación sobre compliance existente

    @Test func recordSession_accumulatesOverExistingCompliance() {
        let habit = makeQuantityHabit(unitName: "min")
        let existing = Compliance(date: .now, completed: false, recordedAmount: 10)
        habit.compliances.append(existing)
        timerVM.selectedMinutes = 15

        timerVM.recordSession(for: habit)

        #expect(habitVM.todayCompliance(for: habit)?.recordedAmount == 25.0)
    }

    // MARK: - Integración: sesión completa

    @Test func integration_multipleSessionsAccumulateAndComplete() {
        let habit = makeQuantityHabit(unitName: "min", dailyGoal: 60)

        timerVM.selectedMinutes = 25
        timerVM.recordSession(for: habit)
        #expect(habitVM.todayCompliance(for: habit)?.recordedAmount == 25)
        #expect(habitVM.todayCompliance(for: habit)?.completed == false)

        timerVM.recordSession(for: habit)
        #expect(habitVM.todayCompliance(for: habit)?.recordedAmount == 50)
        #expect(habitVM.todayCompliance(for: habit)?.completed == false)

        timerVM.selectedMinutes = 10
        timerVM.recordSession(for: habit)
        #expect(habitVM.todayCompliance(for: habit)?.recordedAmount == 60)
        #expect(habitVM.todayCompliance(for: habit)?.completed == true)
    }
}
