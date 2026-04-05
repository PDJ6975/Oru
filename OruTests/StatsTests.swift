import Testing
import Foundation
@testable import Oru

// MARK: - 1. Métricas globales

@MainActor
@Suite(.serialized)
struct StatsGlobalMetricsTests {

    private let vm: StatsViewModel
    private let habitRepo: MockHabitRepository
    private let origamiRepo: MockOrigamiRepository
    private let cal = Calendar.current

    init() {
        habitRepo = MockHabitRepository()
        origamiRepo = MockOrigamiRepository()
        vm = StatsViewModel(repository: habitRepo, origamiRepository: origamiRepo)
    }

    // MARK: - Helpers

    private func daysAgo(_ offset: Int) -> Date {
        // swiftlint:disable:next force_unwrapping
        cal.date(byAdding: .day, value: -offset, to: cal.startOfDay(for: .now))!
    }

    @discardableResult
    private func makeHabit(
        name: String = "Test",
        scheduledDays: [Habit.Weekday] = Habit.Weekday.allCases,
        creationDate: Date? = nil,
        status: Habit.HabitStatus = .active
    ) -> Habit {
        let habit = Habit(
            icon: "🧪",
            name: name,
            type: .boolean,
            scheduledDays: scheduledDays,
            creationDate: creationDate ?? daysAgo(4),
            status: status
        )
        habitRepo.habits.append(habit)
        return habit
    }

    private func addCompliance(
        to habit: Habit,
        daysAgo offset: Int,
        completed: Bool = true
    ) {
        let compliance = Compliance(
            date: daysAgo(offset),
            completed: completed
        )
        habit.compliances.append(compliance)
    }

    // MARK: - Tests

    // 1 hábito (todos los días), creado hace 4 días -> 5 días programados
    // 3 completados -> 3/5 × 100 = 60%
    @Test func complianceRate_basic() {
        let habit = makeHabit()
        addCompliance(to: habit, daysAgo: 4)
        addCompliance(to: habit, daysAgo: 3)
        addCompliance(to: habit, daysAgo: 1)

        vm.loadStats()

        #expect(vm.complianceRate == 60.0)
    }

    // Sin hábitos -> compliance rate = 0
    @Test func complianceRate_noHabits() {
        vm.loadStats()

        #expect(vm.complianceRate == 0)
    }

    // 2 hábitos: A con 4 completados, B con 2 -> total = 6
    @Test func habitsCompleted_multipleHabits() {
        let habitA = makeHabit(name: "A", creationDate: daysAgo(6))
        let habitB = makeHabit(name: "B", creationDate: daysAgo(6))
        for day in [6, 5, 3, 1] { addCompliance(to: habitA, daysAgo: day) }
        for day in [4, 2] { addCompliance(to: habitB, daysAgo: day) }

        vm.loadStats()

        #expect(vm.habitsCompleted == 6)
    }

    // 2 hábitos creados hace 2 días -> días -2, -1, 0
    // Día -2: ambos completados -> perfecto
    // Día -1: solo A -> no perfecto
    // Día 0 (hoy): ninguno
    @Test func perfectDays_basic() {
        let habitA = makeHabit(name: "A", creationDate: daysAgo(2))
        let habitB = makeHabit(name: "B", creationDate: daysAgo(2))
        addCompliance(to: habitA, daysAgo: 2)
        addCompliance(to: habitB, daysAgo: 2)
        addCompliance(to: habitA, daysAgo: 1)

        vm.loadStats()

        #expect(vm.perfectDays == 1)
    }

    // 1 hábito creado hace 3 días, completado días -3, -2, -1
    // Hoy está programado pero sin completar -> no rompe la racha
    @Test func currentStreak_todayDoesNotBreak() {
        let habit = makeHabit(creationDate: daysAgo(3))
        addCompliance(to: habit, daysAgo: 3)
        addCompliance(to: habit, daysAgo: 2)
        addCompliance(to: habit, daysAgo: 1)

        vm.loadStats()

        #expect(vm.currentStreak == 3)
    }

    // 5 días perfectos, 1 fallo, 2 perfectos → bestStreak=5, currentStreak=2
    @Test func bestStreak_afterBreak() {
        let habit = makeHabit(creationDate: daysAgo(8))
        // Días -8, -7, -6, -5, -4 -> 5 perfectos
        for day in [8, 7, 6, 5, 4] { addCompliance(to: habit, daysAgo: day) }
        // Día -3 → fallo (sin compliance)
        // Días -2, -1 -> 2 perfectos
        addCompliance(to: habit, daysAgo: 2)
        addCompliance(to: habit, daysAgo: 1)

        vm.loadStats()

        #expect(vm.bestStreak == 5)
        #expect(vm.currentStreak == 2)
    }

    // Día sin hábitos programados entre dos perfectos no rompe la racha
    // Hábito solo lun-vie, el fin de semana no cuenta
    // Fechas fijas: jue 26-mar, vie 27-mar, (sáb-dom), lun 30-mar = "hoy"
    @Test func streak_daysWithoutScheduled() {
        // swiftlint:disable:next force_unwrapping
        let monday = cal.date(from: DateComponents(year: 2026, month: 3, day: 30))!
        // swiftlint:disable:next force_unwrapping
        let friday = cal.date(byAdding: .day, value: -3, to: monday)!
        // swiftlint:disable:next force_unwrapping
        let thursday = cal.date(byAdding: .day, value: -1, to: friday)!

        let fixedVM = StatsViewModel(
            repository: habitRepo,
            origamiRepository: origamiRepo,
            currentDate: { monday }
        )

        let weekdays: [Habit.Weekday] = [
            .monday, .tuesday, .wednesday, .thursday, .friday
        ]
        let habit = makeHabit(
            scheduledDays: weekdays,
            creationDate: cal.date(byAdding: .day, value: -7, to: thursday)
                ?? thursday
        )

        habit.compliances.append(Compliance(date: thursday, completed: true))
        habit.compliances.append(Compliance(date: friday, completed: true))
        habit.compliances.append(Compliance(date: monday, completed: true))

        fixedVM.loadStats()

        // jue✓ + vie✓ + (sáb-dom no programados) + lun✓(hoy) = racha 3
        #expect(fixedVM.currentStreak == 3)
    }
}

// MARK: - 2. Métricas por hábito individual

@MainActor
@Suite(.serialized)
struct StatsHabitMetricsTests {

    private let vm: StatsViewModel
    private let habitRepo: MockHabitRepository
    private let origamiRepo: MockOrigamiRepository
    private let cal = Calendar.current

    init() {
        habitRepo = MockHabitRepository()
        origamiRepo = MockOrigamiRepository()
        vm = StatsViewModel(repository: habitRepo, origamiRepository: origamiRepo)
    }

    private func daysAgo(_ offset: Int) -> Date {
        // swiftlint:disable:next force_unwrapping
        cal.date(byAdding: .day, value: -offset, to: cal.startOfDay(for: .now))!
    }

    private func addCompliance(
        to habit: Habit,
        daysAgo offset: Int,
        completed: Bool = true,
        amount: Double? = nil
    ) {
        habit.compliances.append(
            Compliance(date: daysAgo(offset), completed: completed, recordedAmount: amount)
        )
    }

    // Hábito boolean: 8 completados, racha actual 3 (días -3,-2,-1),
    // mejor racha 5 (días -10,-9,-8,-7,-6), fallos en -5 y -4
    @Test func habitStats_boolean() {
        let habit = Habit(
            icon: "🧪", name: "Bool",
            type: .boolean,
            scheduledDays: Habit.Weekday.allCases,
            creationDate: daysAgo(10)
        )
        habitRepo.habits.append(habit)

        // Racha de 5: días -10 a -6
        for day in [10, 9, 8, 7, 6] { addCompliance(to: habit, daysAgo: day) }
        // Fallos: -5, -4 (sin compliance)
        // Racha de 3: días -3 a -1
        for day in [3, 2, 1] { addCompliance(to: habit, daysAgo: day) }

        vm.loadStats()

        let stat = vm.habitStats.first
        #expect(stat?.totalCompleted == 8)
        #expect(stat?.bestStreak == 5)
        #expect(stat?.currentStreak == 3)
    }

    // Hábito quantity con amounts [3, 5, 7] -> total 15, media 5
    @Test func habitStats_quantity() {
        let habit = Habit(
            icon: "🧪", name: "Cantidad",
            type: .quantity,
            scheduledDays: Habit.Weekday.allCases,
            creationDate: daysAgo(3)
        )
        habitRepo.habits.append(habit)
        addCompliance(to: habit, daysAgo: 3, amount: 3)
        addCompliance(to: habit, daysAgo: 2, amount: 5)
        addCompliance(to: habit, daysAgo: 1, amount: 7)

        vm.loadStats()

        let stat = vm.habitStats.first
        #expect(stat?.totalAccumulated == 15)
        #expect(stat?.dailyAverage == 5)
    }

    // Hábito boolean no tiene totalAccumulated ni dailyAverage
    @Test func habitStats_booleanNoAccumulated() {
        let habit = Habit(
            icon: "🧪", name: "Bool",
            type: .boolean,
            scheduledDays: Habit.Weekday.allCases,
            creationDate: daysAgo(1)
        )
        habitRepo.habits.append(habit)
        addCompliance(to: habit, daysAgo: 1)

        vm.loadStats()

        let stat = vm.habitStats.first
        #expect(stat?.totalAccumulated == nil)
        #expect(stat?.dailyAverage == nil)
    }

    // 2 hábitos: A con score alto, B con score bajo -> A primero
    @Test func habitStats_ordering() {
        let habitA = Habit(
            icon: "🧪", name: "A",
            type: .boolean,
            scheduledDays: Habit.Weekday.allCases,
            creationDate: daysAgo(5)
        )
        let habitB = Habit(
            icon: "🧪", name: "B",
            type: .boolean,
            scheduledDays: Habit.Weekday.allCases,
            creationDate: daysAgo(5)
        )
        habitRepo.habits.append(contentsOf: [habitA, habitB])
        // A: 5 completados con racha de 5 -> score = 5 × 1.5 = 7.5
        for day in [5, 4, 3, 2, 1] { addCompliance(to: habitA, daysAgo: day) }
        // B: 1 completado con racha de 1 -> score = 1 × 1.1 = 1.1
        addCompliance(to: habitB, daysAgo: 1)

        vm.loadStats()

        #expect(vm.habitStats.count == 2)
        #expect(vm.habitStats[0].habit === habitA)
        #expect(vm.habitStats[1].habit === habitB)
    }
}

// MARK: - 3. Hábitos archivados

@MainActor
@Suite(.serialized)
struct StatsArchivedTests {

    private let vm: StatsViewModel
    private let habitRepo: MockHabitRepository
    private let origamiRepo: MockOrigamiRepository
    private let cal = Calendar.current

    init() {
        habitRepo = MockHabitRepository()
        origamiRepo = MockOrigamiRepository()
        vm = StatsViewModel(repository: habitRepo, origamiRepository: origamiRepo)
    }

    private func daysAgo(_ offset: Int) -> Date {
        // swiftlint:disable:next force_unwrapping
        cal.date(byAdding: .day, value: -offset, to: cal.startOfDay(for: .now))!
    }

    // Hábito archivado hace 5 días con 3 completados (días -10, -9, -8)
    // Esos 3 deben aparecer en habitsCompleted global
    @Test func archived_contributesToGlobal() {
        let habit = Habit(
            icon: "🧪", name: "Archivado",
            type: .boolean,
            scheduledDays: Habit.Weekday.allCases,
            creationDate: daysAgo(10),
            status: .archived
        )
        habit.archivedDate = daysAgo(5)
        habitRepo.habits.append(habit)
        for day in [10, 9, 8] {
            habit.compliances.append(
                Compliance(date: daysAgo(day), completed: true)
            )
        }

        vm.loadStats()

        #expect(vm.habitsCompleted == 3)
    }

    // Hábito archivado hace 5 días: días posteriores al archivado
    // no cuentan como programados ni afectan métricas globales
    @Test func archived_stopsAfterDate() {
        let habit = Habit(
            icon: "🧪", name: "Archivado",
            type: .boolean,
            scheduledDays: Habit.Weekday.allCases,
            creationDate: daysAgo(10),
            status: .archived
        )
        habit.archivedDate = daysAgo(5)
        habitRepo.habits.append(habit)
        // Completado todos los días desde -10 hasta -6 (antes de archivar)
        for day in [10, 9, 8, 7, 6] {
            habit.compliances.append(
                Compliance(date: daysAgo(day), completed: true)
            )
        }

        vm.loadStats()

        // 6 días programados (-10 a -5), 5 completados -> rate = 5/6 × 100
        let expectedRate = 5.0 / 6.0 * 100.0
        #expect(vm.complianceRate == expectedRate)
        // Días -4 a 0 no cuentan como programados (ya archivado)
        #expect(vm.habitsCompleted == 5)
    }

    // 1 activo + 1 archivado -> listas separadas
    @Test func archived_separateList() {
        let activo = Habit(
            icon: "🧪", name: "Activo",
            type: .boolean,
            scheduledDays: Habit.Weekday.allCases,
            creationDate: daysAgo(3)
        )
        let archivado = Habit(
            icon: "🧪", name: "Archivado",
            type: .boolean,
            scheduledDays: Habit.Weekday.allCases,
            creationDate: daysAgo(10),
            status: .archived
        )
        archivado.archivedDate = daysAgo(5)
        habitRepo.habits.append(contentsOf: [activo, archivado])

        // Al menos 1 compliance cada uno para que aparezcan en stats
        activo.compliances.append(
            Compliance(date: daysAgo(1), completed: true)
        )
        archivado.compliances.append(
            Compliance(date: daysAgo(8), completed: true)
        )

        vm.loadStats()

        #expect(vm.habitStats.count == 1)
        #expect(vm.habitStats.first?.habit === activo)
        #expect(vm.archivedHabitStats.count == 1)
        #expect(vm.archivedHabitStats.first?.habit === archivado)
    }
}

// MARK: - 4. Filtrado por año

@MainActor
@Suite(.serialized)
struct StatsYearFilterTests {

    private let vm: StatsViewModel
    private let habitRepo: MockHabitRepository
    private let origamiRepo: MockOrigamiRepository
    private let cal = Calendar.current

    init() {
        habitRepo = MockHabitRepository()
        origamiRepo = MockOrigamiRepository()
        vm = StatsViewModel(repository: habitRepo, origamiRepository: origamiRepo)
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        // swiftlint:disable:next force_unwrapping
        cal.date(from: DateComponents(year: year, month: month, day: day))!
    }

    // Compliances en 2025 y 2026, selectedYear=2026 -> solo métricas de 2026
    @Test func yearFilter_currentYear() {
        let habit = Habit(
            icon: "🧪", name: "Test",
            type: .boolean,
            scheduledDays: Habit.Weekday.allCases,
            creationDate: date(year: 2025, month: 6, day: 1)
        )
        habitRepo.habits.append(habit)

        // 2 compliances en 2025
        habit.compliances.append(Compliance(date: date(year: 2025, month: 7, day: 1), completed: true))
        habit.compliances.append(Compliance(date: date(year: 2025, month: 8, day: 1), completed: true))
        // 3 compliances en 2026
        habit.compliances.append(Compliance(date: date(year: 2026, month: 1, day: 6), completed: true))
        habit.compliances.append(Compliance(date: date(year: 2026, month: 1, day: 7), completed: true))
        habit.compliances.append(Compliance(date: date(year: 2026, month: 1, day: 8), completed: true))

        vm.loadStats() // selectedYear = 2026 por defecto

        #expect(vm.habitsCompleted == 3)
    }

    // selectedYear=2025 -> rango termina el 31-dic-2025
    @Test func yearFilter_pastYear() {
        let habit = Habit(
            icon: "🧪", name: "Test",
            type: .boolean,
            scheduledDays: Habit.Weekday.allCases,
            creationDate: date(year: 2025, month: 6, day: 1)
        )
        habitRepo.habits.append(habit)

        habit.compliances.append(Compliance(date: date(year: 2025, month: 7, day: 1), completed: true))
        habit.compliances.append(Compliance(date: date(year: 2025, month: 8, day: 1), completed: true))
        habit.compliances.append(Compliance(date: date(year: 2026, month: 1, day: 6), completed: true))

        vm.loadStats()
        vm.selectedYear = 2025

        #expect(vm.habitsCompleted == 2)
    }

    // Cambiar selectedYear recalcula métricas automáticamente
    @Test func yearFilter_changeYear() {
        let habit = Habit(
            icon: "🧪", name: "Test",
            type: .boolean,
            scheduledDays: Habit.Weekday.allCases,
            creationDate: date(year: 2025, month: 6, day: 1)
        )
        habitRepo.habits.append(habit)

        habit.compliances.append(Compliance(date: date(year: 2025, month: 7, day: 1), completed: true))
        habit.compliances.append(Compliance(date: date(year: 2026, month: 1, day: 6), completed: true))

        vm.loadStats()
        #expect(vm.habitsCompleted == 1) // 2026

        vm.selectedYear = 2025
        #expect(vm.habitsCompleted == 1) // 2025

        vm.selectedYear = 2026
        #expect(vm.habitsCompleted == 1) // vuelve a 2026
    }

    // Hábito creado en 2024, año actual 2026 -> [2026, 2025, 2024]
    @Test func availableYears_range() {
        let habit = Habit(
            icon: "🧪", name: "Test",
            type: .boolean,
            scheduledDays: Habit.Weekday.allCases,
            creationDate: date(year: 2024, month: 3, day: 1)
        )
        habitRepo.habits.append(habit)

        vm.loadStats()

        #expect(vm.availableYears == [2026, 2025, 2024])
    }
}

// MARK: - 5. Origamis filtrados por año

@MainActor
@Suite(.serialized)
struct StatsOrigamiFilterTests {

    private let vm: StatsViewModel
    private let habitRepo: MockHabitRepository
    private let origamiRepo: MockOrigamiRepository
    private let cal = Calendar.current

    init() {
        habitRepo = MockHabitRepository()
        origamiRepo = MockOrigamiRepository()
        vm = StatsViewModel(repository: habitRepo, origamiRepository: origamiRepo)
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        // swiftlint:disable:next force_unwrapping
        cal.date(from: DateComponents(year: year, month: month, day: day))!
    }

    @discardableResult
    private func makeOrigami(name: String, completionDate: Date?) -> UserOrigami {
        let origami = Origami(name: name, numberOfPhases: 3)
        let uo = UserOrigami(
            completed: true,
            completionDate: completionDate,
            progressPercentage: 100
        )
        uo.origami = origami
        origamiRepo.userOrigamis.append(uo)
        return uo
    }

    // 2 origamis en 2025, 1 en 2026 -> selectedYear=2026 muestra 1
    @Test func origamis_filteredByYear() {
        makeOrigami(name: "Grulla", completionDate: date(year: 2025, month: 5, day: 10))
        makeOrigami(name: "Rana", completionDate: date(year: 2025, month: 9, day: 20))
        makeOrigami(name: "Mariposa", completionDate: date(year: 2026, month: 2, day: 14))

        vm.loadStats()

        #expect(vm.completedOrigamis.count == 1)
        #expect(vm.completedOrigamis.first?.origami?.name == "Mariposa")
    }

    // Cambiar a 2025 muestra los 2 de ese año
    @Test func origamis_changeYear() {
        makeOrigami(name: "Grulla", completionDate: date(year: 2025, month: 5, day: 10))
        makeOrigami(name: "Rana", completionDate: date(year: 2025, month: 9, day: 20))
        makeOrigami(name: "Mariposa", completionDate: date(year: 2026, month: 2, day: 14))

        vm.loadStats()
        vm.selectedYear = 2025

        #expect(vm.completedOrigamis.count == 2)
    }

    // Origami con completionDate nil se excluye
    @Test func origamis_noCompletionDate() {
        makeOrigami(name: "Grulla", completionDate: date(year: 2026, month: 1, day: 5))
        makeOrigami(name: "Roto", completionDate: nil)

        vm.loadStats()

        #expect(vm.completedOrigamis.count == 1)
    }
}

// MARK: - 6. Casos límite

@MainActor
@Suite(.serialized)
struct StatsEdgeCaseTests {

    private let vm: StatsViewModel
    private let habitRepo: MockHabitRepository
    private let origamiRepo: MockOrigamiRepository
    private let cal = Calendar.current

    init() {
        habitRepo = MockHabitRepository()
        origamiRepo = MockOrigamiRepository()
        vm = StatsViewModel(repository: habitRepo, origamiRepository: origamiRepo)
    }

    // Hábito creado hoy, completado hoy -> totalCompleted=1, currentStreak=1
    @Test func edge_singleDay() {
        let today = cal.startOfDay(for: .now)
        let habit = Habit(
            icon: "🧪", name: "Hoy",
            type: .boolean,
            scheduledDays: Habit.Weekday.allCases,
            creationDate: today
        )
        habit.compliances.append(Compliance(date: today, completed: true))
        habitRepo.habits.append(habit)

        vm.loadStats()

        #expect(vm.habitStats.first?.totalCompleted == 1)
        #expect(vm.habitStats.first?.currentStreak == 1)
    }

    // Compliance con completed=false no cuenta
    @Test func edge_complianceNotCompleted() {
        let habit = Habit(
            icon: "🧪", name: "Falso",
            type: .boolean,
            scheduledDays: Habit.Weekday.allCases,
            creationDate: cal.date(byAdding: .day, value: -3, to: cal.startOfDay(for: .now))
                ?? .now
        )
        // 3 compliances con completed=false
        for offset in [3, 2, 1] {
            let date = cal.date(
                byAdding: .day, value: -offset, to: cal.startOfDay(for: .now)
            ) ?? .now
            habit.compliances.append(Compliance(date: date, completed: false))
        }
        habitRepo.habits.append(habit)

        vm.loadStats()

        #expect(vm.habitsCompleted == 0)
        #expect(vm.currentStreak == 0)
    }

}
