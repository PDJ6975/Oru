import SwiftUI
import SwiftData

struct HomeView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var navigateToHabits = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color(.systemBackground)
                .ignoresSafeArea()

            Image(systemName: "checklist")
                .foregroundStyle(Color.secondary)
                .frame(width: 50, height: 50)
                .glassEffect(.regular.interactive())
                .oruPulse { navigateToHabits = true }
                .navigationDestination(isPresented: $navigateToHabits) {
                    HabitListView(
                        viewModel: HabitViewModel(
                            repository: HabitRepository(modelContext: modelContext)
                        )
                    )
                }
                .padding(24)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .modelContainer(for: Habit.self, inMemory: true)
}
