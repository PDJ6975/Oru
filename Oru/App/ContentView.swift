import SwiftUI
import SwiftData

struct ContentView: View {

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.modelContext) private var modelContext
    @State private var showNameRegistration = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else if showNameRegistration {
                NameRegistrationView(
                    viewModel: WelcomeViewModel(
                        repository: UserRepository(modelContext: modelContext),
                        origamiRepository: OrigamiRepository(modelContext: modelContext)
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
}

#Preview {
    ContentView()
        .modelContainer(for: User.self, inMemory: true)
}
