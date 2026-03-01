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
            OrigamiPhase.self,
            Quote.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
