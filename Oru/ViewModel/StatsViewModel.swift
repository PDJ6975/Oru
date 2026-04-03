import Foundation
import SwiftData

@Observable
class StatsViewModel {

    private let repository: HabitRepositoryProtocol
    private let origamiRepository: OrigamiRepositoryProtocol
    private let calendar = Calendar.current
    private let currentDate: () -> Date

    var selectedYear: Int {
        didSet { recomputeMetrics() }
    }

    private(set) var habits: [Habit] = []
    private(set) var lastError: String?

    // Métricas globales
    private(set) var complianceRate: Double = 0
    private(set) var currentStreak: Int = 0
    private(set) var bestStreak: Int = 0
    private(set) var habitsCompleted: Int = 0
    private(set) var perfectDays: Int = 0

    // Métricas por hábito (ordenadas por puntuación descendente)
    private(set) var habitStats: [HabitStats] = []
    private(set) var archivedHabitStats: [HabitStats] = []

    // Origamis completados por el usuario (filtrados por año seleccionado)
    private(set) var completedOrigamis: [UserOrigami] = []
    private var allCompletedOrigamis: [UserOrigami] = []

    init(
        repository: HabitRepositoryProtocol,
        origamiRepository: OrigamiRepositoryProtocol,
        currentDate: @escaping () -> Date = { .now }
    ) {
        self.repository = repository
        self.origamiRepository = origamiRepository
        self.currentDate = currentDate
        self.selectedYear = calendar.component(.year, from: currentDate())
    }

    func loadStats() {
        do {
            habits = try repository.fetchAllHabits()
            allCompletedOrigamis = try origamiRepository.fetchCompletedOrigamis()
            recomputeMetrics()
        } catch {
            lastError = "No se pudieron cargar las estadísticas: \(error.localizedDescription)"
            habits = []
            allCompletedOrigamis = []
            completedOrigamis = []
        }
    }

    var availableYears: [Int] {
        let currentYear = calendar.component(.year, from: currentDate())
        guard let earliest = habits.map(\.creationDate).min() else {
            return [currentYear]
        }
        let startYear = calendar.component(.year, from: earliest)
        return Array(startYear...currentYear).reversed()
    }

    // MARK: - Rango del año seleccionado

    // Devuelve (inicio, fin) del rango a analizar:
    // - Inicio: 1 de enero del año seleccionado
    // - Fin: hoy si es el año actual, o 31 de diciembre si es un año pasado
    private func yearRange() -> (start: Date, end: Date) {
        let start = calendar.date(from: DateComponents(year: selectedYear)) ?? .now // ej: 1-ene-2026
        let nextYearStart = calendar.date(from: DateComponents(year: selectedYear + 1)) ?? .now // ej: 1-ene-2027
        let lastDayOfYear = calendar.date(byAdding: .day, value: -1, to: nextYearStart) ?? nextYearStart // le restamos un día: 31-dic-2026
        let today = calendar.startOfDay(for: currentDate())
        return (start, min(today, lastDayOfYear))
    }

    // MARK: - Estadísticas por hábito

    struct HabitStats: Identifiable {
        let habit: Habit
        let currentStreak: Int
        let bestStreak: Int
        let totalCompleted: Int
        let totalAccumulated: Double?  // Solo para hábitos de cantidad (suma de recordedAmount)
        let dailyAverage: Double?  // Solo para hábitos de cantidad
        let score: Double

        var id: ObjectIdentifier { ObjectIdentifier(habit) }
    }

    // MARK: - Estructuras auxiliares para el cálculo unificado

    // Acumula datos globales de cada día: cuántos hábitos había programados y cuántos se completaron
    // Ejemplo: el 13-ene tiene scheduled=2 (Meditar + Correr) y completed=1 (solo Meditar)
    private struct DayInfo {
        var scheduled: Int = 0
        var completed: Int = 0
        var isPerfect: Bool { scheduled > 0 && completed >= scheduled }
    }

    // Acumula rachas y total por hábito individual durante el recorrido día a día
    // Se actualiza en el mismo bucle que DayInfo, evitando un segundo recorrido
    private struct HabitAccumulator {
        var currentStreak: Int = 0
        var bestStreak: Int = 0
        var totalCompleted: Int = 0
    }

    // MARK: - Cálculo unificado de métricas (global + hábitos individuales)
    //
    // Paso 1 -> Índice de completados y cantidades (una pasada sobre compliances)
    // Paso 2 -> Bucle día a día único (actualiza DayInfo global + HabitAccumulator por hábito)
    // Paso 3 -> Deriva métricas globales de los DayInfo
    // Paso 4 -> Construye HabitStats de los acumuladores
    //
    // Ejemplo: Meditar (boolean, lun-vie, creado 10-ene) y Correr (quantity, lun-mie-vie, creado 20-ene)
    // Fecha actual: lunes 27 de enero

    // Orquesta el cálculo: llama a yearRange() una sola vez y pasa el rango a cada paso
    // today se pasa a los pasos de rachas para que hoy no rompa una racha (el día aún no ha terminado)
    private func recomputeMetrics() {
        let range = yearRange()
        let today = calendar.startOfDay(for: currentDate())
        let index = buildComplianceIndex(range: range)
        let (daily, accumulators) = computeDayByDay(range: range, index: index, today: today)
        deriveGlobalMetrics(daily: daily, range: range, today: today)
        let (active, archived) = buildHabitStats(accumulators: accumulators, amounts: index.amounts)
        habitStats = active
        archivedHabitStats = archived
        completedOrigamis = allCompletedOrigamis.filter { uo in
            guard let date = uo.completionDate else { return false }
            return date >= range.start && date <= range.end
        }
    }

    // ── Paso 1: índice de días completados y cantidades registradas por hábito ──
    // Para cada hábito, recorremos sus compliances una sola vez y extraemos:
    // - completed: conjunto de fechas donde completó
    // - amounts: lista de cantidades registradas (solo para hábitos de cantidad)
    //
    // Ejemplo resultado:
    //   completed = { Meditar: {10-ene, 11-ene, 13-ene, ...}, Correr: {20-ene, 22-ene, ...} }
    //   amounts = { Correr: [5.0, 3.5, 7.0, ...] }
    private struct ComplianceIndex {
        var completed: [ObjectIdentifier: Set<Date>] = [:]
        var amounts: [ObjectIdentifier: [Double]] = [:]
    }

    private func buildComplianceIndex(range: (start: Date, end: Date)) -> ComplianceIndex {
        var index = ComplianceIndex()
        for habit in habits {
            let key = ObjectIdentifier(habit)
            var dates: Set<Date> = []
            var amounts: [Double] = []
            for compliance in habit.compliances where compliance.completed {
                let day = calendar.startOfDay(for: compliance.date)
                guard day >= range.start, day <= range.end else { continue }
                dates.insert(day)
                if let amount = compliance.recordedAmount { amounts.append(amount) }
            }
            index.completed[key] = dates
            if habit.type == .quantity, !amounts.isEmpty { index.amounts[key] = amounts }
        }
        return index
    }

    // ── Paso 2: recorrido único día a día ──
    // Iteramos desde el 1 de enero hasta hoy (año actual) o 31 de diciembre (año pasado).
    // En cada día, para cada hábito que esté programado ese día:
    //   - Actualizamos DayInfo global (scheduled/completed del día)
    //   - Actualizamos HabitAccumulator individual (racha y total del hábito)
    //
    // Los archivados contribuyen a métricas globales solo hasta su archivedDate.
    // Ejemplo: Nadar (creado 1-mar, archivado 15-jun) solo cuenta de mar a jun.
    //
    // Ejemplo para el lunes 13-ene:
    //   Meditar: creado 10-ene ≤ 13-ene ✓, tiene lunes ✓ -> scheduled+1
    //     ¿completedDays[Meditar] contiene 13-ene? -> sí -> completed+1, racha+1
    //   Correr: creado 20-ene > 13-ene -> skip (aún no existía)
    //   Resultado día: DayInfo(scheduled=1, completed=1) -> día perfecto ✓
    private func computeDayByDay(
        range: (start: Date, end: Date),
        index: ComplianceIndex,
        today: Date
    ) -> (daily: [Date: DayInfo], accumulators: [ObjectIdentifier: HabitAccumulator]) {
        var daily: [Date: DayInfo] = [:]
        var accumulators: [ObjectIdentifier: HabitAccumulator] = [:]
        var day = range.start

        // Precomputar fechas de inicio y fin de cada hábito para no recalcularlas O(días × hábitos) veces
        // fin = archivedDate si archivado, nil si activo/consolidado (sin límite)
        let habitRanges: [ObjectIdentifier: (start: Date, end: Date?)] = Dictionary(
            uniqueKeysWithValues: habits.map {
                let end = $0.archivedDate.map { calendar.startOfDay(for: $0) }
                return (ObjectIdentifier($0), (calendar.startOfDay(for: $0.creationDate), end))
            }
        )

        while day <= range.end {
            let wd = weekday(from: day)
            for habit in habits {
                let key = ObjectIdentifier(habit)
                guard let habitRange = habitRanges[key],
                      habitRange.start <= day,
                      habit.scheduledDays.contains(wd) else { continue }

                // Si el hábito fue archivado antes de este día, no cuenta
                if let end = habitRange.end, day > end { continue }

                let wasCompleted = index.completed[key]?.contains(day) == true

                // Global: programado y completado para este día
                daily[day, default: DayInfo()].scheduled += 1
                if wasCompleted { daily[day, default: DayInfo()].completed += 1 }

                // Por hábito: si completó -> racha+1
                // Si no completó Y no es hoy -> racha se rompe
                // Hoy no rompe la racha porque el día aún no ha terminado
                var acc = accumulators[key, default: HabitAccumulator()]
                if wasCompleted {
                    acc.currentStreak += 1
                    acc.bestStreak = max(acc.bestStreak, acc.currentStreak)
                    acc.totalCompleted += 1
                } else if day != today {
                    acc.currentStreak = 0
                }
                accumulators[key] = acc
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return (daily, accumulators)
    }

    // ── Paso 3: derivar métricas globales de los DayInfo ──
    // habitsCompleted: suma de todos los completed de cada día
    // complianceRate: (completados / programados) × 100
    // perfectDays: días donde se completaron todos los programados
    // Rachas globales: días perfectos consecutivos (los días sin hábitos programados no rompen la racha)
    private func deriveGlobalMetrics(daily: [Date: DayInfo], range: (start: Date, end: Date), today: Date) {
        habitsCompleted = daily.values.reduce(0) { $0 + $1.completed }
        let totalScheduled = daily.values.reduce(0) { $0 + $1.scheduled }
        complianceRate = totalScheduled > 0
            ? Double(habitsCompleted) / Double(totalScheduled) * 100
            : 0
        perfectDays = daily.values.filter(\.isPerfect).count

        // Rachas globales de días perfectos consecutivos
        var globalCurrent = 0
        var globalBest = 0
        var day = range.start
        while day <= range.end {
            if let info = daily[day] {
                if info.isPerfect {
                    globalCurrent += 1
                    globalBest = max(globalBest, globalCurrent)
                } else if day != today {
                    globalCurrent = 0
                }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        currentStreak = globalCurrent
        bestStreak = globalBest
    }

    // Transforma los acumuladores en HabitStats ordenados por puntuación
    // Separa activos/consolidados de archivados en una sola pasada
    // Puntuación = Completados × (1 + RachaActual / 10)
    // Ejemplo: Meditar con 15 completados y racha de 8 -> 15 × 1.8 = 27.0
    private func buildHabitStats(
        accumulators: [ObjectIdentifier: HabitAccumulator],
        amounts: [ObjectIdentifier: [Double]]
    ) -> (active: [HabitStats], archived: [HabitStats]) {
        var active: [HabitStats] = []
        var archived: [HabitStats] = []

        for habit in habits {
            let key = ObjectIdentifier(habit)
            guard let acc = accumulators[key] else { continue }

            let stats = makeHabitStats(habit: habit, acc: acc, amounts: amounts[key])
            if habit.status == .archived {
                archived.append(stats)
            } else {
                active.append(stats)
            }
        }

        active.sort { $0.score > $1.score }
        archived.sort { $0.score > $1.score }
        return (active, archived)
    }

    // Construye un HabitStats individual a partir de su acumulador y cantidades
    private func makeHabitStats(
        habit: Habit,
        acc: HabitAccumulator,
        amounts: [Double]?
    ) -> HabitStats {
        var totalAccumulated: Double?
        var dailyAverage: Double?
        if let habitAmounts = amounts {
            let sum = habitAmounts.reduce(0, +)
            totalAccumulated = sum
            dailyAverage = sum / Double(habitAmounts.count)
        }

        let score = Double(acc.totalCompleted) * (1.0 + Double(acc.currentStreak) / 10.0)

        return HabitStats(
            habit: habit,
            currentStreak: acc.currentStreak,
            bestStreak: acc.bestStreak,
            totalCompleted: acc.totalCompleted,
            totalAccumulated: totalAccumulated,
            dailyAverage: dailyAverage,
            score: score
        )
    }
}
