import Testing
import Foundation
@testable import Oru

@MainActor
@Suite(.serialized)
struct HabitTests {

    private let vm: HabitViewModel
    private let repo: MockHabitRepository

    init() {
        repo = MockHabitRepository()
        vm = HabitViewModel(repository: repo)
    }

    // MARK: - Helpers

    private func makeHabit(
        type: Habit.HabitType = .boolean,
        dailyGoal: Double? = nil
    ) -> Habit {
        Habit(
            icon: "🧪",
            name: "Test",
            type: type,
            scheduledDays: Habit.Weekday.allCases,
            dailyGoal: dailyGoal
        )
    }

    private func makeHabitWithCompliances(count: Int) -> Habit {
        let habit = makeHabit()
        guard count > 0 else { return habit }
        for dayOffset in 1...count {
            let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: .now) ?? .now
            habit.compliances.append(Compliance(date: date, completed: true))
        }
        return habit
    }

    // MARK: - Marcado booleano

    @Test func toggleBoolean_createsCompliance() throws {
        let habit = makeHabit()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
        habit.compliances.append(Compliance(date: yesterday, completed: true))

        #expect(vm.todayCompliance(for: habit) == nil)

        vm.toggleBoolean(for: habit)

        let compliance = try #require(vm.todayCompliance(for: habit))
        #expect(compliance.completed == true)
        #expect(Calendar.current.isDateInToday(compliance.date))
    }

    @Test func toggleBoolean_togglesExisting() {
        let habit = makeHabit()
        vm.toggleBoolean(for: habit) // completed: true

        vm.toggleBoolean(for: habit) // invierte a false

        #expect(vm.todayCompliance(for: habit)?.completed == false)
    }

    // MARK: - Registro de cantidades

    @Test func recordAmount_createsCompliance() throws {
        let habit = makeHabit(type: .quantity)

        vm.recordAmount(3, for: habit)

        let compliance = try #require(vm.todayCompliance(for: habit))
        #expect(compliance.recordedAmount == 3)
    }

    @Test func recordAmount_zeroDeletesCompliance() {
        let habit = makeHabit(type: .quantity)
        vm.recordAmount(5, for: habit)

        vm.recordAmount(0, for: habit)

        #expect(vm.todayCompliance(for: habit) == nil)
    }

    @Test func recordAmount_updatesExisting() throws {
        let habit = makeHabit(type: .quantity)
        vm.recordAmount(3, for: habit)

        vm.recordAmount(7, for: habit)

        let compliance = try #require(vm.todayCompliance(for: habit))
        #expect(compliance.recordedAmount == 7)
        #expect(habit.compliances.count == 1)
    }

    @Test func recordAmount_completionReflectsGoal() {
        let habit = makeHabit(type: .quantity, dailyGoal: 5)

        vm.recordAmount(3, for: habit)
        #expect(vm.todayCompliance(for: habit)?.completed == false)

        vm.recordAmount(5, for: habit)
        #expect(vm.todayCompliance(for: habit)?.completed == true)
    }

    // MARK: - Objetivo

    @Test func isGoalMet_reflectsGoal() {
        let habit = makeHabit(type: .quantity, dailyGoal: 5)

        #expect(habit.isGoalMet(3) == false)
        #expect(habit.isGoalMet(5) == true)
    }

    // MARK: - 4. Unidades personalizadas

    @Test func addCustomUnit_success() {
        let result = vm.addCustomUnit(name: "pasos")

        #expect(result == true)
        #expect(repo.units.count == 1)
        #expect(repo.units.first?.name == "pasos")
    }

    @Test func addCustomUnit_emptyName() {
        let result = vm.addCustomUnit(name: "   ")

        #expect(result == false)
        #expect(repo.units.isEmpty)
    }

    @Test func addCustomUnit_duplicateName() {
        repo.units.append(Oru.Unit(name: "pasos", origin: .custom))

        let result = vm.addCustomUnit(name: "Pasos")

        #expect(result == false)
        #expect(repo.units.count == 1)
    }

    @Test func addCustomUnit_baseUnitName() {
        repo.units.append(Oru.Unit(name: "km", origin: .base))

        let result = vm.addCustomUnit(name: "km")

        #expect(result == false)
        #expect(repo.units.count == 1)
    }

    @Test func addCustomUnit_maxLimitReached() {
        for idx in 0..<Oru.Unit.maxCustomCount {
            repo.units.append(Oru.Unit(name: "u\(idx)", origin: .custom))
        }

        let result = vm.addCustomUnit(name: "extra")

        #expect(result == false)
        #expect(repo.units.count == Oru.Unit.maxCustomCount)
    }

    @Test func renameUnit_success() {
        let unit = Oru.Unit(name: "pasos", origin: .custom)
        repo.units.append(unit)

        let result = vm.renameUnit(unit, to: "zancadas")

        #expect(result == true)
        #expect(unit.name == "zancadas")
    }

    @Test func renameUnit_duplicateName() {
        let unit = Oru.Unit(name: "pasos", origin: .custom)
        let other = Oru.Unit(name: "km", origin: .base)
        repo.units.append(contentsOf: [unit, other])

        let result = vm.renameUnit(unit, to: "km")

        #expect(result == false)
        #expect(unit.name == "pasos")
    }

    // MARK: - 5. Consolidación y archivado

    @Test func consolidation_at66_changesStatus() {
        let habit = makeHabitWithCompliances(count: 65)

        vm.toggleBoolean(for: habit) // compliance nº 66

        #expect(habit.status == .consolidated)
    }

    @Test func consolidation_at65_remainsActive() {
        let habit = makeHabitWithCompliances(count: 64)

        vm.toggleBoolean(for: habit) // compliance nº 65

        #expect(habit.status == .active)
    }

    @Test func consolidation_revert_below66() {
        let habit = makeHabitWithCompliances(count: 65)
        vm.toggleBoolean(for: habit) // nº 66 -> consolidated
        #expect(habit.status == .consolidated)

        vm.toggleBoolean(for: habit) // desmarcar hoy -> 65 completed -> active

        #expect(habit.status == .active)
    }

    @Test func archiveHabit_setsStatusAndDate() throws {
        let habit = makeHabit()
        let before = Date.now

        vm.archiveHabit(habit)

        #expect(habit.status == .archived)
        let archivedDate = try #require(habit.archivedDate)
        #expect(archivedDate >= before)
    }

    // MARK: - 6. Validación

    @Test func isValidHabit_validInput() {
        let result = vm.isValidHabit(
            name: "Leer",
            selectedDays: [.monday, .wednesday],
            type: .boolean,
            dailyGoal: nil
        )

        #expect(result == true)
    }

    @Test func isValidHabit_emptyName() {
        let result = vm.isValidHabit(
            name: "   ",
            selectedDays: [.monday],
            type: .boolean,
            dailyGoal: nil
        )

        #expect(result == false)
    }

    @Test func isValidHabit_noDays() {
        let result = vm.isValidHabit(
            name: "Leer",
            selectedDays: [],
            type: .boolean,
            dailyGoal: nil
        )

        #expect(result == false)
    }

    @Test func isValidHabit_quantityWithoutGoal() {
        let result = vm.isValidHabit(
            name: "Correr",
            selectedDays: [.monday],
            type: .quantity,
            dailyGoal: nil
        )

        #expect(result == false)
    }

    @Test func isValidHabit_quantityWithGoal() {
        let result = vm.isValidHabit(
            name: "Correr",
            selectedDays: [.monday],
            type: .quantity,
            dailyGoal: 5
        )

        #expect(result == true)
    }

    @Test func clampName_exceedsLimit() {
        let name = "Este nombre es muy largo para el límite"

        let result = vm.clampName(name)

        #expect(result.count == Habit.maxNameLength)
        #expect(result == String(name.prefix(Habit.maxNameLength)))
    }
}
