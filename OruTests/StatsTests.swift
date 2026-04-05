import Testing
import Foundation
@testable import Oru

@MainActor
@Suite(.serialized)
struct StatsTests {

    private let habitRepo: MockHabitRepository
    private let origamiRepo: MockOrigamiRepository
    private let vm: StatsViewModel
    private let cal = Calendar.current

    init() {
        habitRepo = MockHabitRepository()
        origamiRepo = MockOrigamiRepository()
        vm = StatsViewModel(repository: habitRepo, origamiRepository: origamiRepo)
    }

    // MARK: - Helpers

    private func daysAgo(_ offset: Int) -> Date {
        cal.date(byAdding: .day, value: -offset, to: cal.startOfDay(for: .now))!
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        cal.date(from: DateComponents(year: year, month: month, day: day))!
    }

    @discardableResult
    private func makeHabit(
        name: String = "Test",
        type: Habit.HabitType = .boolean,
        scheduledDays: [Habit.Weekday] = Habit.Weekday.allCases,
        creationDate: Date? = nil,
        status: Habit.HabitStatus = .active
    ) -> Habit {
        let habit = Habit(
            icon: "🧪",
            name: name,
            type: type,
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
        completed: Bool = true,
        amount: Double? = nil
    ) {
        habit.compliances.append(
            Compliance(date: daysAgo(offset), completed: completed, recordedAmount: amount)
        )
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

    // MARK: - Métricas globales con dos hábitos
    // 2 hábitos boolean (todos los días), creados hace 4 días -> 5 días programados c/u = 10 total
    // A: completa días -4, -3, -1 (3); B: completa días -4, -3 (2) -> 5/10 completados
    // Días perfectos: -4 y -3 (ambos completaron)
    @Test func globalMetrics_twoHabits() {
        #expect(vm.complianceRate == 0) // pre-load: sin datos = 0

        let habitA = makeHabit(name: "A")
        let habitB = makeHabit(name: "B")
        addCompliance(to: habitA, daysAgo: 4)
        addCompliance(to: habitA, daysAgo: 3)
        addCompliance(to: habitA, daysAgo: 1)
        addCompliance(to: habitB, daysAgo: 4)
        addCompliance(to: habitB, daysAgo: 3)

        vm.loadStats()

        #expect(vm.habitsCompleted == 5)
        #expect(vm.complianceRate == 50.0)
        #expect(vm.perfectDays == 2)
    }

    // MARK: - Racha global con ruptura y hoy sin completar
    // A y B: perfectos días -8 a -4 (bestStreak=5), día -3 solo A (ruptura global),
    // días -2 y -1 perfectos (currentStreak=2), hoy sin completar (no rompe)
    @Test func globalStreak_breakAndToday() {
        let habitA = makeHabit(name: "A", creationDate: daysAgo(8))
        let habitB = makeHabit(name: "B", creationDate: daysAgo(8))

        for day in [8, 7, 6, 5, 4] {
            addCompliance(to: habitA, daysAgo: day)
            addCompliance(to: habitB, daysAgo: day)
        }
        addCompliance(to: habitA, daysAgo: 3) // solo A en día -3 -> ruptura global
        for day in [2, 1] {
            addCompliance(to: habitA, daysAgo: day)
            addCompliance(to: habitB, daysAgo: day)
        }
        // Hoy (día 0): ninguno completa

        vm.loadStats()

        #expect(vm.bestStreak == 5)
        #expect(vm.currentStreak == 2)
    }

    // MARK: - Racha global con días sin programar
    // Hábito programado solo en el día de la semana de hoy, completado 3 semanas seguidas.
    // Los 6 días no programados entre cada semana no rompen la racha -> currentStreak = 3
    @Test func globalStreak_scheduledGap() {
        let todayWeekday = weekday(from: cal.startOfDay(for: .now))
        let habit = makeHabit(
            scheduledDays: [todayWeekday],
            creationDate: daysAgo(14)
        )
        addCompliance(to: habit, daysAgo: 14)
        addCompliance(to: habit, daysAgo: 7)
        addCompliance(to: habit, daysAgo: 0)

        vm.loadStats()

        #expect(vm.currentStreak == 3)
    }

    // MARK: - Estadísticas por hábito: boolean y quantity
    // A (boolean): racha bestStreak=5 (días -10 a -6), falla -5 y -4, racha currentStreak=3 (días -3 a -1)
    // B (quantity): amounts [3, 5, 7] -> totalAccumulated=15, dailyAverage=5
    // habitStats[0] = A (score 8×1.3=10.4 > B 3×1.3=3.9)
    @Test func habitStats_booleanAndQuantity() {
        let habitA = makeHabit(name: "A", creationDate: daysAgo(10))
        let habitB = makeHabit(name: "B", type: .quantity, creationDate: daysAgo(3))

        for day in [10, 9, 8, 7, 6] { addCompliance(to: habitA, daysAgo: day) }
        for day in [3, 2, 1] { addCompliance(to: habitA, daysAgo: day) }

        addCompliance(to: habitB, daysAgo: 3, amount: 3)
        addCompliance(to: habitB, daysAgo: 2, amount: 5)
        addCompliance(to: habitB, daysAgo: 1, amount: 7)

        vm.loadStats()

        let statA = vm.habitStats.first { $0.habit === habitA }
        let statB = vm.habitStats.first { $0.habit === habitB }

        #expect(statA?.totalCompleted == 8)
        #expect(statA?.bestStreak == 5)
        #expect(statA?.currentStreak == 3)
        #expect(statA?.totalAccumulated == nil)
        #expect(statB?.totalAccumulated == 15)
        #expect(statB?.dailyAverage == 5)
        #expect(vm.habitStats[0].habit === habitA)
    }

    // MARK: - Hábito archivado: métricas y separación
    // C activo (creado hace 3 días): completa día -1 -> 1/4 programados
    // D archivado (creado hace 10 días, archivado hace 5 días): completa -10 a -6 -> 5/6 programados
    // habitsCompleted=6, complianceRate=60%, listas separadas
    @Test func archived_metricsAndSeparation() {
        let habitC = makeHabit(name: "C", creationDate: daysAgo(3))
        let habitD = makeHabit(name: "D", creationDate: daysAgo(10), status: .archived)
        habitD.archivedDate = daysAgo(5)

        addCompliance(to: habitC, daysAgo: 1)
        for day in 6...10 { addCompliance(to: habitD, daysAgo: day) }

        vm.loadStats()

        #expect(vm.habitsCompleted == 6)
        #expect(vm.complianceRate == 6.0 / 10.0 * 100.0)
        #expect(vm.habitStats.count == 1)
        #expect(vm.archivedHabitStats.count == 1)
        #expect(vm.habitStats[0].habit === habitC)
        #expect(vm.archivedHabitStats[0].habit === habitD)
    }

    // MARK: - 6. Filtro por año y años disponibles
    // 1 hábito creado jun-2024, 2 compliances en 2025, 3 en 2026
    // Por defecto selectedYear=2026 -> habitsCompleted=3
    // Cambiar a 2025 -> habitsCompleted=2; availableYears=[2026, 2025, 2024]
    @Test func yearFilter_andAvailableYears() {
        let habit = makeHabit(creationDate: date(year: 2024, month: 6, day: 1))
        habit.compliances.append(Compliance(date: date(year: 2025, month: 7, day: 1), completed: true))
        habit.compliances.append(Compliance(date: date(year: 2025, month: 8, day: 1), completed: true))
        habit.compliances.append(Compliance(date: date(year: 2026, month: 1, day: 6), completed: true))
        habit.compliances.append(Compliance(date: date(year: 2026, month: 1, day: 7), completed: true))
        habit.compliances.append(Compliance(date: date(year: 2026, month: 1, day: 8), completed: true))

        vm.loadStats() // selectedYear = 2026 por defecto

        #expect(vm.habitsCompleted == 3)

        vm.selectedYear = 2025

        #expect(vm.habitsCompleted == 2)
        #expect(vm.availableYears == [2026, 2025, 2024])
    }

    // MARK: - 7. Origamis filtrados por año
    // Grulla (may-2025), Rana (sep-2025), Mariposa (feb-2026)
    // selectedYear=2026 -> solo Mariposa
    @Test func origamis_filteredByYear() {
        makeOrigami(name: "Grulla", completionDate: date(year: 2025, month: 5, day: 10))
        makeOrigami(name: "Rana", completionDate: date(year: 2025, month: 9, day: 20))
        makeOrigami(name: "Mariposa", completionDate: date(year: 2026, month: 2, day: 14))

        vm.loadStats()

        #expect(vm.completedOrigamis.count == 1)
        #expect(vm.completedOrigamis[0].origami?.name == "Mariposa")
    }
}
