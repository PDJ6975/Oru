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

    // MARK: - Seed
    func seedOrigamisIfNeeded() throws

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

    // MARK: - Seed

    func seedOrigamisIfNeeded() throws {
        let descriptor = FetchDescriptor<Origami>()
        let existingNames = Set(try modelContext.fetch(descriptor).map(\.name))

        let catalog: [(name: String, phases: Int)] = [
            ("mariposa", 5),
            ("bailarina", 6),
            ("flor", 6),
            ("luna", 6)
        ]

        var didInsert = false
        for entry in catalog where !existingNames.contains(entry.name) {
            let origami = Origami(name: entry.name, numberOfPhases: entry.phases)
            modelContext.insert(origami)

            for phase in 0..<entry.phases {
                let op = OrigamiPhase(
                    phaseNumber: phase,
                    illustrationName: "\(entry.name)_fase\(phase)"
                )
                op.origami = origami
                modelContext.insert(op)
            }
            didInsert = true
        }

        if didInsert { try saveChanges() }
    }

    // MARK: - Persistencia

    func saveChanges() throws {
        try modelContext.save()
    }
}
