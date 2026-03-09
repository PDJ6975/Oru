import SwiftUI
import SwiftData

@Observable
class HabitViewModel {

    private let repository: HabitRepositoryProtocol

    var habits: [Habit] = []
    var lastError: String?

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
            lastError = "No se pudieron cargar los hábitos: \(error.localizedDescription)"
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
        do {
            try repository.saveChanges()
        } catch {
            lastError = "No se pudo guardar el cambio: \(error.localizedDescription)"
        }
    }

    // Si la cantidad es 0 y ya existe un compliance, lo elimina
    // Si la cantidad es > 0, crea o actualiza el compliance
    func recordAmount(_ amount: Double, for habit: Habit) {
        do {
            if amount <= 0 {
                if let compliance = todayCompliance(for: habit) {
                    habit.compliances.removeAll { $0 === compliance }
                    try repository.deleteCompliance(compliance)
                }
            } else if let compliance = todayCompliance(for: habit) {
                compliance.recordedAmount = amount
                compliance.completed = true
            } else {
                let compliance = Compliance(date: .now, completed: true, recordedAmount: amount)
                compliance.habit = habit
            }
            try repository.saveChanges()
        } catch {
            lastError = "No se pudo registrar la cantidad: \(error.localizedDescription)"
        }
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

    // MARK: - Validación

    static let maxNameLength = 40
    static let maxGoalLength = 5
    static let maxNoteLength = 200

    func isValidHabit(name: String, selectedDays: Set<Habit.Weekday>) -> Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !selectedDays.isEmpty
    }

    func clampName(_ value: String) -> String {
        String(value.prefix(Self.maxNameLength))
    }

    func clampGoal(_ value: String) -> String {
        String(value.prefix(Self.maxGoalLength))
    }

    func clampNote(_ value: String) -> String {
        String(value.prefix(Self.maxNoteLength))
    }

    // MARK: - Creación y edición de hábitos

    func addHabit(_ habit: Habit) {
        do {
            try repository.addHabit(habit)
            loadHabits()
        } catch {
            lastError = "No se pudo crear el hábito: \(error.localizedDescription)"
        }
    }

    func updateHabit(_ habit: Habit, with data: FormData) {
        habit.icon = data.icon
        habit.name = data.name
        habit.type = data.type
        habit.scheduledDays = data.scheduledDays
        habit.dailyGoal = data.dailyGoal
        habit.note = data.note
        habit.unit = data.unit
        do {
            try repository.saveChanges()
            loadHabits()
        } catch {
            lastError = "No se pudo actualizar el hábito: \(error.localizedDescription)"
        }
    }

    func fetchUnits() -> [Unit] {
        do {
            return try repository.fetchAllUnits()
        } catch {
            lastError = "No se pudieron cargar las unidades: \(error.localizedDescription)"
            return []
        }
    }

    // MARK: - Tipos auxiliares

    struct FormData {
        let icon: String
        let name: String
        let type: Habit.HabitType
        let scheduledDays: [Habit.Weekday]
        let dailyGoal: Double?
        let note: String?
        let unit: Unit?
    }
}
