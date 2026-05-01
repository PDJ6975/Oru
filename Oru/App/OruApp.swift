import SwiftUI
import SwiftData

@main
struct OruApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            Habit.self,
            Unit.self,
            Compliance.self,
            Origami.self,
            UserOrigami.self, 
            OrigamiPhase.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: modelConfiguration)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        if CommandLine.arguments.contains("-resetOnboarding") {
            UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        }

        let context = sharedModelContainer.mainContext
        let habitRepository = HabitRepository(modelContext: context)
        try? habitRepository.seedBaseUnitsIfNeeded()
        let origamiRepository = OrigamiRepository(modelContext: context)
        try? origamiRepository.seedOrigamisIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
