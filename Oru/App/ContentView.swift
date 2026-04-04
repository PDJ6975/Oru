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
                        repository: UserRepository(modelContext: modelContext)
                    ),
                    onRegistered: {
                        assignFirstOrigami()
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

    private func assignFirstOrigami() {
        let origamiRepo = OrigamiRepository(modelContext: modelContext)
        let userRepo = UserRepository(modelContext: modelContext)
        guard let user = try? userRepo.fetchUser(),
              let origami = try? origamiRepo.fetchNextOrigami() else { return }

        let userOrigami = UserOrigami()
        userOrigami.user = user
        userOrigami.origami = origami
        try? origamiRepo.addUserOrigami(userOrigami)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: User.self, inMemory: true)
}
