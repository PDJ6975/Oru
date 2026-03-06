import SwiftUI
import SwiftData

struct ContentView: View {

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.modelContext) private var modelContext
    @State private var showNameRegistration = false

    var body: some View {
        if hasCompletedOnboarding {
            TabView {
                Text("Hábitos")
                    .tabItem {
                        Label("Hábitos", systemImage: "list.bullet")
                    }

                Text("Estadísticas")
                    .tabItem {
                        Label("Stats", systemImage: "chart.bar")
                    }

                Text("Gamificación")
                    .tabItem {
                        Label("Origamis", systemImage: "star")
                    }

                Text("Temporizador")
                    .tabItem {
                        Label("Timer", systemImage: "timer")
                    }
            }
        } else if showNameRegistration {
            NameRegistrationView(
                viewModel: WelcomeViewModel(
                    repository: UserRepository(modelContext: modelContext)
                ),
                onRegistered: {
                    withAnimation {
                        hasCompletedOnboarding = true
                    }
                }
            )
            .transition(.push(from: .trailing))
        } else {
            WelcomeView {
                withAnimation {
                    showNameRegistration = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: User.self, inMemory: true)
}
