import Foundation
import SwiftData

// Main Actor permite sincronizar la vista con los datos.
// Es decir, las vistas corren en el hilo principal.
// Sin main actor, el repositorio puede devolver datos en hilos secundarios.
// Así, permite que todo salga por el hilo principal y se sincronice bien.
@MainActor
protocol HabitRepositoryProtocol {
    // MARK: - Habit
    func fetchAllHabits() throws -> [Habit]
    func fetchActiveHabits() throws -> [Habit]
    func addHabit(_ habit: Habit) throws
    func deleteHabit(_ habit: Habit) throws

    // MARK: - Compliance
    func deleteCompliance(_ compliance: Compliance) throws

    // MARK: - Unit
    func fetchAllUnits() throws -> [Unit]
    func fetchBaseUnits() throws -> [Unit]
    func addUnit(_ unit: Unit) throws
    func deleteUnit(_ unit: Unit) throws

    // MARK: - Seed
    func seedBaseUnitsIfNeeded() throws

    // MARK: - Persistencia
    func saveChanges() throws
}

@MainActor
final class HabitRepository: HabitRepositoryProtocol {
    
    // Model Context es quien tiene todos los objetos en memoria,
    // antes de guardar en la base de datos.
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Habit

    func fetchAllHabits() throws -> [Habit] {
        // FetchDescriptor es la definición técnica de una consulta,
        // para que el ModelContext sepa qué buscar en BD.
        let descriptor = FetchDescriptor<Habit>(
            sortBy: [SortDescriptor(\.creationDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchActiveHabits() throws -> [Habit] {
        let activeRaw = Habit.HabitStatus.active.rawValue
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { $0.status.rawValue == activeRaw },
            sortBy: [SortDescriptor(\.creationDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func addHabit(_ habit: Habit) throws {
        modelContext.insert(habit)
        try saveChanges()
    }

    func deleteHabit(_ habit: Habit) throws {
        modelContext.delete(habit)
        try saveChanges()
    }

    // MARK: - Compliance

    func deleteCompliance(_ compliance: Compliance) throws {
        modelContext.delete(compliance)
        try saveChanges()
    }

    // MARK: - Unit

    func fetchAllUnits() throws -> [Unit] {
        let descriptor = FetchDescriptor<Unit>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchBaseUnits() throws -> [Unit] {
        let all = try fetchAllUnits()
        return all.filter { $0.origin == .base }
    }

    func addUnit(_ unit: Unit) throws {
        modelContext.insert(unit)
        try saveChanges()
    }

    func deleteUnit(_ unit: Unit) throws {
        modelContext.delete(unit)
        try saveChanges()
    }

    // MARK: - Seed

    func seedBaseUnitsIfNeeded() throws {
        let existing = try fetchAllUnits()
        let existingNames = Set(existing.map(\.name))

        let baseNames = ["uds", "min", "h", "km", "m", "kg", "g", "L", "cal", "págs"]
        let newUnits = baseNames.filter { !existingNames.contains($0) }
        guard !newUnits.isEmpty else { return }

        for name in newUnits {
            modelContext.insert(Unit(name: name, origin: .base))
        }
        try saveChanges()
    }

    // MARK: - Persistencia

    func saveChanges() throws {
        try modelContext.save()
    }
}
