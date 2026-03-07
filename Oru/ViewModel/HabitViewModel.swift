import SwiftUI
import SwiftData

@Observable
class HabitViewModel {

    private let repository: HabitRepositoryProtocol

    var habits: [Habit] = []

    var todayHabits: [Habit] {
        let today = currentWeekday()
        return habits.filter { $0.scheduledDays.contains(today) }
    }

    var otherHabits: [Habit] {
        let today = currentWeekday()
        return habits.filter { !$0.scheduledDays.contains(today) }
    }

    init(repository: HabitRepositoryProtocol) {
        self.repository = repository
    }

    func loadHabits() {
        do {
            habits = try repository.fetchAllHabits().filter { $0.status == .active }
        } catch {
            habits = []
        }
    }
    
    // Interruptor de hábitos booleanos
    // Si existe un Compliance en el día actual -> lo invierte
    // Si no existe -> Crea un compliance para hoy como completado
    func toggleBoolean(for habit: Habit) {
        if let compliance = todayCompliance(for: habit) {
            compliance.completed.toggle()
        } else {
            let compliance = Compliance(date: .now, completed: true)
            compliance.habit = habit
        }
        try? repository.saveChanges()
    }

    // Si la cantidad es 0 y ya existe un compliance, lo elimina
    // Si la cantidad es > 0, crea o actualiza el compliance
    func recordAmount(_ amount: Double, for habit: Habit) {
        if amount <= 0 {
            if let compliance = todayCompliance(for: habit) {
                habit.compliances.removeAll { $0 === compliance }
                try? repository.deleteCompliance(compliance)
            }
        } else if let compliance = todayCompliance(for: habit) {
            compliance.recordedAmount = amount
            compliance.completed = true
        } else {
            let compliance = Compliance(date: .now, completed: true, recordedAmount: amount)
            compliance.habit = habit
        }
        try? repository.saveChanges()
    }
    
    // Devuelve si existe un registro de cumplimiento para un hábito en el día actual
    func todayCompliance(for habit: Habit) -> Compliance? {
        // isDateInToday ignora las horas de la fecha para asegurar un solo registro
        habit.compliances.first { Calendar.current.isDateInToday($0.date) }
    }
    
    // Convierte el día de la semana del calendario internacional a nuestro modelo
    // Si es domingo: 1 -> 7; Si es otro día: n - 1
    // Calendar.component(.weekday): 1=domingo, 2=lunes...7=sábado
    // Habit.Weekday: 1=lunes...7=domingo
    func currentWeekday() -> Habit.Weekday {
        let calendarWeekday = Calendar.current.component(.weekday, from: .now)
        let mapped = calendarWeekday == 1 ? 7 : calendarWeekday - 1
        return Habit.Weekday(rawValue: mapped) ?? .monday
    }
}
