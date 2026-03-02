import Foundation
import SwiftData

@MainActor
protocol ComplianceRepositoryProtocol {
    func fetchCompliances(for habit: Habit) throws -> [Compliance]
    func fetchCompliances(for habit: Habit, year: Int) throws -> [Compliance]
    func fetchCompliance(for habit: Habit, on date: Date) throws -> Compliance?
    func addCompliance(_ compliance: Compliance, to habit: Habit) throws
    func deleteCompliance(_ compliance: Compliance) throws
    func deleteAllCompliances(for habit: Habit) throws
    func saveChanges() throws
}

@MainActor
final class ComplianceRepository: ComplianceRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchCompliances(for habit: Habit) throws -> [Compliance] {
        let habitName = habit.name
        let habitCreationDate = habit.creationDate
        let descriptor = FetchDescriptor<Compliance>(
            predicate: #Predicate {
                $0.habit?.name == habitName
                    && $0.habit?.creationDate == habitCreationDate
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchCompliances(for habit: Habit, year: Int) throws -> [Compliance] {
        let habitName = habit.name
        let habitCreationDate = habit.creationDate
        var components = DateComponents()
        components.year = year
        let startOfYear = Calendar.current.date(from: components) ?? .now
        components.year = year + 1
        let startOfNextYear = Calendar.current.date(from: components) ?? .now
        let descriptor = FetchDescriptor<Compliance>(
            predicate: #Predicate {
                $0.habit?.name == habitName
                    && $0.habit?.creationDate == habitCreationDate
                    && $0.date >= startOfYear
                    && $0.date < startOfNextYear
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchCompliance(for habit: Habit, on date: Date) throws -> Compliance? {
        let habitName = habit.name
        let habitCreationDate = habit.creationDate
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        let descriptor = FetchDescriptor<Compliance>(
            predicate: #Predicate {
                $0.habit?.name == habitName
                    && $0.habit?.creationDate == habitCreationDate
                    && $0.date >= startOfDay
                    && $0.date < endOfDay
            }
        )
        return try modelContext.fetch(descriptor).first
    }

    func addCompliance(_ compliance: Compliance, to habit: Habit) throws {
        compliance.habit = habit
        modelContext.insert(compliance)
        try saveChanges()
    }

    func deleteCompliance(_ compliance: Compliance) throws {
        modelContext.delete(compliance)
        try saveChanges()
    }

    func deleteAllCompliances(for habit: Habit) throws {
        let compliances = try fetchCompliances(for: habit)
        for compliance in compliances {
            modelContext.delete(compliance)
        }
        try saveChanges()
    }

    func saveChanges() throws {
        try modelContext.save()
    }
}
