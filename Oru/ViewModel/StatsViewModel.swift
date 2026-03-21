import Foundation
import SwiftData

@Observable
class StatsViewModel {

    private let repository: HabitRepositoryProtocol
    private let calendar = Calendar.current

    var selectedYear: Int {
        didSet { recomputeMetrics() }
    }

    private(set) var habits: [Habit] = []
    private(set) var lastError: String?

    // Métricas calculadas
    var complianceRate: Double = 0
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    var habitsCompleted: Int = 0
    var perfectDays: Int = 0

    init(repository: HabitRepositoryProtocol) {
        self.repository = repository
        self.selectedYear = Calendar.current.component(.year, from: .now)
    }

    func loadStats() {
        do {
            habits = try repository.fetchAllHabits()
            recomputeMetrics() // Orquesta el cálculo de estadísticas en general
        } catch {
            lastError = "No se pudieron cargar las estadísticas: \(error.localizedDescription)"
            habits = []
        }
    }

    var availableYears: [Int] {
        let currentYear = calendar.component(.year, from: .now)
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
        let start = calendar.date(from: DateComponents(year: selectedYear)) ?? .now
        let nextYearStart = calendar.date(from: DateComponents(year: selectedYear + 1)) ?? .now
        let today = calendar.startOfDay(for: .now)
        return (start, min(today, nextYearStart))
    }

    // MARK: - Cálculo de métricas

    private func recomputeMetrics() {
        let daily = computeDailyStats() // Devuelvue un diccinario donde para cada día te dice hábitos planificados, completados y si es día perfecto
        habitsCompleted = daily.values.reduce(0) { $0 + $1.completed } // $0 es un acumulador en 0 y $1.complete se va sumando para cada día al acumulador
        complianceRate = computeComplianceRate(daily: daily)
        perfectDays = daily.values.filter(\.isPerfect).count
        let streaks = computeStreaks(daily: daily)
        currentStreak = streaks.current
        bestStreak = streaks.best
    }

    private func computeComplianceRate(daily: [Date: DayInfo]) -> Double {
        let totalScheduled = daily.values.reduce(0) { $0 + $1.scheduled } // para hábitos totales completados usamos directamente habitsCompleted
        guard totalScheduled > 0 else { return 0 }
        return Double(habitsCompleted) / Double(totalScheduled) * 100
    }

    // Calcula las dos rachas (current y best) en un solo recorrido hacia adelante:
    // - current: racha de días perfectos consecutivos que llega hasta hoy
    // - best: la mayor racha de días perfectos consecutivos en el año
    // Los días sin hábitos programados no rompen la racha (no están en daily)
    private func computeStreaks(daily: [Date: DayInfo]) -> (current: Int, best: Int) {
        let range = yearRange()
        var best = 0
        var current = 0
        var day = range.start

        while day <= range.end {
            if let info = daily[day] {
                if info.isPerfect {
                    current += 1
                    best = max(best, current)
                } else {
                    current = 0
                }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return (current, best)
    }

    // MARK: - Estadísticas diarias

    private struct DayInfo {
        var scheduled: Int = 0
        var completed: Int = 0
        var isPerfect: Bool { scheduled > 0 && completed >= scheduled }
    }
    
    // Construye un diccionario donde cada entrada dice cuántos
    // hábitos había programados para ese día y cuántos se completaron
    private func computeDailyStats() -> [Date: DayInfo] {
        let range = yearRange()

        // Índice de días completados por hábito
        var completedDays: [ObjectIdentifier: Set<Date>] = [:]
        for habit in habits {
            var dates: Set<Date> = []
            for compliance in habit.compliances where compliance.completed {
                let day = calendar.startOfDay(for: compliance.date)
                if day >= range.start, day <= range.end {
                    dates.insert(day)
                }
            }
            completedDays[ObjectIdentifier(habit)] = dates // ej: completedDays = { habitMeditar: {10-ene, 11-ene, 13-ene}, habitCorrer:  {20-ene, 22-ene} }
        }

        var stats: [Date: DayInfo] = [:]
        var day = range.start

        // Iteramos desde 1 de enero hasta hoy si el año es el presente
        // o desde el 1 de enero hasta el 31 de diciembre si es pasado
        // Usaremos de ejemplo Meditar (lun-vie, creado 10 de enero) y Correr(lun-mie-vie, creado 20 enero)
        // Usaremos de ejemplo como fecha actual el lunes 13 de enero
        while day <= range.end {
            let wd = weekday(from: day) // obtenemos el día de la semana del día (if 13 enero -> lunes)
            for habit in habits {
                let habitStart = calendar.startOfDay(for: habit.creationDate)
                guard habitStart <= day, habit.scheduledDays.contains(wd) else { continue } // Para meditar: 10 ene <= 13 ene -> sí -> tiene lunes en scheduled? -> sí
                stats[day, default: DayInfo()].scheduled += 1 // como lo tiene -> +=1 en scheduled
                if completedDays[ObjectIdentifier(habit)]?.contains(day) == true {
                    stats[day, default: DayInfo()].completed += 1 // sí el hábito tiene el 13 como completado, entonces es que lo completó -> +1 completed ese día
                }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return stats
    }
}
