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
final class MockOrigamiRepository: OrigamiRepositoryProtocol {
    var userOrigamis: [UserOrigami] = []
    var origamis: [Origami] = []

    func fetchNextOrigami() throws -> Origami? {
        let assignedNames = Set(userOrigamis.compactMap { $0.origami?.name })
        return origamis.first { !assignedNames.contains($0.name) }
    }

    func fetchPhases(for origami: Origami) throws -> [OrigamiPhase] {
        origami.phases.sorted { $0.phaseNumber < $1.phaseNumber }
    }

    func fetchCurrentUserOrigami() throws -> UserOrigami? {
        userOrigamis.first { !$0.completed }
    }

    func fetchCompletedOrigamis() throws -> [UserOrigami] {
        userOrigamis.filter(\.completed)
    }

    func addUserOrigami(_ userOrigami: UserOrigami) throws {
        userOrigamis.append(userOrigami)
    }

    func seedOrigamisIfNeeded() throws {}
    func saveChanges() throws {}
}
