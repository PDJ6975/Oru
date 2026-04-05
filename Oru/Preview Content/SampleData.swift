import SwiftUI
import SwiftData

// MARK: - PreviewModifier con datos completos

struct SampleData: PreviewModifier {
    static func makeSharedContext() throws -> ModelContainer {
        let schema = Schema([
            User.self, Habit.self, Unit.self, Compliance.self,
            Origami.self, UserOrigami.self, OrigamiPhase.self, Quote.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        SampleDataFactory.populateFullContext(container.mainContext)
        return container
    }

    func body(content: Content, context: ModelContainer) -> some View {
        content
            .modelContainer(context)
            .oruDefaultTint() // Para ver en el preview el color real reseteado
    }
}

// MARK: - PreviewModifier vacío (para vistas sin datos)

struct EmptyContainerData: PreviewModifier {
    static func makeSharedContext() throws -> ModelContainer {
        let schema = Schema([
            User.self, Habit.self, Unit.self, Compliance.self,
            Origami.self, UserOrigami.self, OrigamiPhase.self, Quote.self
        ])
        return try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
        )
    }

    func body(content: Content, context: ModelContainer) -> some View {
        content
            .modelContainer(context)
            .oruDefaultTint()
    }
}

// MARK: - PreviewTrait shortcuts

extension PreviewTrait where T == Preview.ViewTraits {
    static var sampleData: PreviewTrait<T> { .modifier(SampleData()) }
    static var emptyContainer: PreviewTrait<T> { .modifier(EmptyContainerData()) }
}
