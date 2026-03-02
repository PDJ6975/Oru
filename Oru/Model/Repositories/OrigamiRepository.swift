import Foundation
import SwiftData

@MainActor
protocol OrigamiRepositoryProtocol {
    // MARK: - Origami
    func fetchNextOrigami() throws -> Origami?
    func fetchPhases(for origami: Origami) throws -> [OrigamiPhase]

    // MARK: - UserOrigami
    func fetchCurrentUserOrigami() throws -> UserOrigami?
    func fetchCompletedOrigamis() throws -> [UserOrigami]
    func addUserOrigami(_ userOrigami: UserOrigami) throws

    // MARK: - Persistencia
    func saveChanges() throws
}

@MainActor
final class OrigamiRepository: OrigamiRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Origami

    func fetchNextOrigami() throws -> Origami? {
        // Obtener los IDs de origamis ya asignados al usuario
        let assignedDescriptor = FetchDescriptor<UserOrigami>()
        let assigned = try modelContext.fetch(assignedDescriptor)
        let assignedNames = Set(assigned.compactMap { $0.origami?.name })

        // Obtener todos los origamis del catálogo
        let allDescriptor = FetchDescriptor<Origami>()
        let allOrigamis = try modelContext.fetch(allDescriptor)

        // Filtrar los no asignados y devolver uno aleatorio
        let available = allOrigamis.filter { !assignedNames.contains($0.name) }
        return available.randomElement()
    }

    func fetchPhases(for origami: Origami) throws -> [OrigamiPhase] {
        let origamiName = origami.name
        let descriptor = FetchDescriptor<OrigamiPhase>(
            predicate: #Predicate { $0.origami?.name == origamiName },
            sortBy: [SortDescriptor(\.phaseNumber)]
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - UserOrigami

    func fetchCurrentUserOrigami() throws -> UserOrigami? {
        let descriptor = FetchDescriptor<UserOrigami>(
            predicate: #Predicate { $0.completed == false }
        )
        return try modelContext.fetch(descriptor).first
    }

    func fetchCompletedOrigamis() throws -> [UserOrigami] {
        let descriptor = FetchDescriptor<UserOrigami>(
            predicate: #Predicate { $0.completed == true }
        )
        return try modelContext.fetch(descriptor)
    }

    func addUserOrigami(_ userOrigami: UserOrigami) throws {
        modelContext.insert(userOrigami)
        try saveChanges()
    }

    // MARK: - Persistencia

    func saveChanges() throws {
        try modelContext.save()
    }
}
