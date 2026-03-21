import Testing
import Foundation
@testable import Oru

@MainActor
final class MockHabitRepository: HabitRepositoryProtocol {
    var habits: [Habit] = []
    var units: [Oru.Unit] = []
    var compliances: [Compliance] = []

    func fetchAllHabits() throws -> [Habit] { habits }
    func fetchActiveHabits() throws -> [Habit] {
        habits.filter { $0.status == .active }
    }
    func addHabit(_ habit: Habit) throws { habits.append(habit) }
    func deleteHabit(_ habit: Habit) throws {
        habits.removeAll { $0 === habit }
    }

    func deleteCompliance(_ compliance: Compliance) throws {
        compliances.removeAll { $0 === compliance }
    }

    func fetchAllUnits() throws -> [Oru.Unit] { units }
    func fetchBaseUnits() throws -> [Oru.Unit] {
        units.filter { $0.origin == .base }
    }
    func addUnit(_ unit: Oru.Unit) throws { units.append(unit) }
    func deleteUnit(_ unit: Oru.Unit) throws {
        units.removeAll { $0 === unit }
    }
    func countHabitsUsingUnit(_ unit: Oru.Unit) throws -> Int {
        habits.filter { $0.unit === unit }.count
    }

    func seedBaseUnitsIfNeeded() throws {}
    func saveChanges() throws {}
}

@MainActor
@Suite(.serialized)
struct HabitCreationTests {

    private let vm: HabitViewModel
    private let repo: MockHabitRepository

    init() {
        repo = MockHabitRepository()
        vm = HabitViewModel(repository: repo)
    }

    @discardableResult
    private func insertHabit(
        name: String = "Test",
        status: Habit.HabitStatus = .active,
        scheduledDays: [Habit.Weekday] = Habit.Weekday.allCases
    ) -> Habit {
        let habit = Habit(
            icon: "🧪",
            name: name,
            type: .boolean,
            scheduledDays: scheduledDays,
            status: status
        )
        repo.habits.append(habit)
        return habit
    }

    // MARK: - Tests

    @Test func loadHabits_filtersArchived() {
        insertHabit(name: "Activo")
        insertHabit(name: "Archivado", status: .archived)

        vm.loadHabits()

        #expect(vm.habits.count == 1)
        #expect(vm.habits.first?.name == "Activo")
    }

    @Test func loadHabits_includesConsolidated() {
        insertHabit(name: "Activo")
        insertHabit(name: "Consolidado", status: .consolidated)

        vm.loadHabits()

        #expect(vm.habits.count == 2)
    }

    @Test func addHabit_appearsInList() {
        let habit = Habit(
            icon: "🧪", name: "Nuevo",
            type: .boolean, scheduledDays: [.monday]
        )

        vm.addHabit(habit)

        #expect(vm.habits.count == 1)
        #expect(vm.habits.first?.name == "Nuevo")
    }

    @Test func deleteHabit_removesFromList() {
        let habit = insertHabit(name: "Borrar")
        vm.loadHabits()

        vm.deleteHabit(habit)

        #expect(vm.habits.isEmpty)
    }

    @Test func todayHabits_filtersCorrectly() {
        let today = vm.currentWeekday()
        let otherDay: Habit.Weekday =
            today == .monday ? .friday : .monday

        insertHabit(name: "Hoy", scheduledDays: [today])
        insertHabit(
            name: "Otro día",
            scheduledDays: [otherDay]
        )
        vm.loadHabits()

        #expect(vm.todayHabits.count == 1)
        #expect(vm.todayHabits.first?.name == "Hoy")
        #expect(vm.otherHabits.count == 1)
        #expect(vm.otherHabits.first?.name == "Otro día")
    }
}

// MARK: - 2. Marcado booleano

@MainActor
@Suite(.serialized)
struct HabitBooleanTests {

    private let vm: HabitViewModel
    private let repo: MockHabitRepository

    init() {
        repo = MockHabitRepository()
        vm = HabitViewModel(repository: repo)
    }

    private func makeHabit() -> Habit {
        let habit = Habit(
            icon: "🧪", name: "Booleano",
            type: .boolean,
            scheduledDays: Habit.Weekday.allCases
        )
        repo.habits.append(habit)
        vm.loadHabits()
        return habit
    }

    @Test func toggleBoolean_createsCompliance() {
        let habit = makeHabit()

        vm.toggleBoolean(for: habit)

        let compliance = vm.todayCompliance(for: habit)
        #expect(compliance != nil)
        #expect(compliance?.completed == true)
    }

    @Test func toggleBoolean_togglesExisting() {
        let habit = makeHabit()
        vm.toggleBoolean(for: habit) // crea con completed: true

        vm.toggleBoolean(for: habit) // invierte a false

        #expect(vm.todayCompliance(for: habit)?.completed == false)
    }

    @Test func toggleBoolean_doubleToggle() {
        let habit = makeHabit()
        vm.toggleBoolean(for: habit) // true
        vm.toggleBoolean(for: habit) // false

        vm.toggleBoolean(for: habit) // true de nuevo

        #expect(vm.todayCompliance(for: habit)?.completed == true)
    }

    @Test func todayCompliance_returnsNilIfNone() {
        let habit = makeHabit()

        #expect(vm.todayCompliance(for: habit) == nil)
    }

    @Test func todayCompliance_ignoresPastDates() {
        let habit = makeHabit()
        let yesterday = Calendar.current.date(
            byAdding: .day, value: -1, to: .now
        )!
        let oldCompliance = Compliance(
            date: yesterday, completed: true
        )
        habit.compliances.append(oldCompliance)

        #expect(vm.todayCompliance(for: habit) == nil)
    }
}

// MARK: - 3. Registro de cantidades

@MainActor
@Suite(.serialized)
struct HabitAmountTests {

    private let vm: HabitViewModel
    private let repo: MockHabitRepository

    init() {
        repo = MockHabitRepository()
        vm = HabitViewModel(repository: repo)
    }

    private func makeQuantityHabit(
        dailyGoal: Double? = nil
    ) -> Habit {
        let habit = Habit(
            icon: "🧪", name: "Cantidad",
            type: .quantity,
            scheduledDays: Habit.Weekday.allCases,
            dailyGoal: dailyGoal
        )
        repo.habits.append(habit)
        vm.loadHabits()
        return habit
    }

    @Test func recordAmount_createsCompliance() {
        let habit = makeQuantityHabit()

        vm.recordAmount(3, for: habit)

        let compliance = vm.todayCompliance(for: habit)
        #expect(compliance != nil)
        #expect(compliance?.recordedAmount == 3)
    }

    @Test func recordAmount_zeroDeletesCompliance() {
        let habit = makeQuantityHabit()
        vm.recordAmount(5, for: habit)

        vm.recordAmount(0, for: habit)

        #expect(vm.todayCompliance(for: habit) == nil)
    }

    @Test func recordAmount_updatesExisting() {
        let habit = makeQuantityHabit()
        vm.recordAmount(3, for: habit)

        vm.recordAmount(7, for: habit)

        let compliance = vm.todayCompliance(for: habit)
        #expect(compliance?.recordedAmount == 7)
        #expect(habit.compliances.count == 1)
    }

    @Test func isGoalMet_withGoal_belowTarget() {
        let habit = makeQuantityHabit(dailyGoal: 5)

        #expect(vm.isGoalMet(3, for: habit) == false)
    }

    @Test func isGoalMet_withGoal_meetsTarget() {
        let habit = makeQuantityHabit(dailyGoal: 5)

        #expect(vm.isGoalMet(5, for: habit) == true)
    }
}

// MARK: - 4. Unidades personalizadas

@MainActor
@Suite(.serialized)
struct HabitCustomUnitTests {

    private let vm: HabitViewModel
    private let repo: MockHabitRepository

    init() {
        repo = MockHabitRepository()
        vm = HabitViewModel(repository: repo)
    }

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

    @Test func addCustomUnit_maxLimitReached() {
        for idx in 0..<Oru.Unit.maxCustomCount {
            repo.units.append(
                Oru.Unit(name: "u\(idx)", origin: .custom)
            )
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
}

// MARK: - 5. Consolidación y archivado

@MainActor
@Suite(.serialized)
struct HabitConsolidationTests {

    private let vm: HabitViewModel
    private let repo: MockHabitRepository

    init() {
        repo = MockHabitRepository()
        vm = HabitViewModel(repository: repo)
    }

    private func makeHabitWithCompliances(
        count: Int
    ) -> Habit {
        let habit = Habit(
            icon: "🧪", name: "Consolidar",
            type: .boolean,
            scheduledDays: Habit.Weekday.allCases
        )
        for dayOffset in 1...count {
            let date = Calendar.current.date(
                byAdding: .day, value: -dayOffset, to: .now
            )!
            let compliance = Compliance(
                date: date, completed: true
            )
            habit.compliances.append(compliance)
        }
        repo.habits.append(habit)
        vm.loadHabits()
        return habit
    }

    @Test func consolidation_at66_changesStatus() {
        let habit = makeHabitWithCompliances(count: 65)

        // El toggle de hoy crea el compliance nº 66
        vm.toggleBoolean(for: habit)

        #expect(habit.status == .consolidated)
    }

    @Test func consolidation_at65_remainsActive() {
        let habit = makeHabitWithCompliances(count: 64)

        // El toggle de hoy crea el compliance nº 65
        vm.toggleBoolean(for: habit)

        #expect(habit.status == .active)
    }

    @Test func consolidation_at66_setsConsolidatedHabit() {
        let habit = makeHabitWithCompliances(count: 65)

        vm.toggleBoolean(for: habit)

        #expect(vm.consolidatedHabit === habit)
    }

    @Test func consolidation_revert_below66() {
        let habit = makeHabitWithCompliances(count: 65)
        vm.toggleBoolean(for: habit) // nº 66 -> consolidated
        #expect(habit.status == .consolidated)

        // Desmarcar hoy -> 65 completed -> vuelve a active
        vm.toggleBoolean(for: habit)

        #expect(habit.status == .active)
    }

    @Test func archiveHabit_changesStatus() {
        let habit = Habit(
            icon: "🧪", name: "Archivar",
            type: .boolean,
            scheduledDays: Habit.Weekday.allCases
        )
        repo.habits.append(habit)
        vm.loadHabits()

        vm.archiveHabit(habit)

        #expect(habit.status == .archived)
    }

    @Test func archiveHabit_removesFromList() {
        let habit = Habit(
            icon: "🧪", name: "Archivar",
            type: .boolean,
            scheduledDays: Habit.Weekday.allCases
        )
        repo.habits.append(habit)
        vm.loadHabits()
        #expect(vm.habits.count == 1)

        vm.archiveHabit(habit)

        #expect(vm.habits.isEmpty)
    }
}

// MARK: - 6. Validación

@MainActor
@Suite(.serialized)
struct HabitValidationTests {

    private let vm: HabitViewModel

    init() {
        vm = HabitViewModel(repository: MockHabitRepository())
    }

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

    @Test func clampName_withinLimit() {
        let name = "Correr" // 6 chars

        #expect(vm.clampName(name) == "Correr")
    }

    @Test func clampName_exceedsLimit() {
        let name = "Este nombre es muy largo" // 24 chars

        let result = vm.clampName(name)

        #expect(result.count == Habit.maxNameLength)
        #expect(result == String(name.prefix(Habit.maxNameLength)))
    }
}
