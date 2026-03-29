import SwiftUI
import SwiftData

struct MainTabView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var gamificationVM: GamificationViewModel?

    var body: some View {
        TabView {
            Tab("Inicio", systemImage: "house") {
                NavigationStack {
                    HomeView(gamificationVM: $gamificationVM)
                }
            }

            Tab("Hábitos", systemImage: "checklist") {
                NavigationStack {
                    makeHabitListView()
                }
            }

            Tab("Estadísticas", systemImage: "chart.bar") {
                NavigationStack {
                    StatsView(viewModel: StatsViewModel(
                        repository: HabitRepository(modelContext: modelContext),
                        origamiRepository: OrigamiRepository(modelContext: modelContext)
                    ))
                }
            }

            Tab("Temporizador", systemImage: "timer") {
                Text("Próximamente")
            }
        }
        .tint(Color.oruPrimary)
        .onAppear {
            if gamificationVM == nil {
                let gvm = GamificationViewModel(
                    origamiRepository: OrigamiRepository(modelContext: modelContext)
                )
                gvm.loadOrigami()
                gamificationVM = gvm
            }
        }
    }

    private func makeHabitListView() -> HabitListView {
        let hvm = HabitViewModel(
            repository: HabitRepository(modelContext: modelContext)
        )
        let gvm = gamificationVM
        hvm.onHabitToggled = { completed, count in
            gvm?.habitToggled(completed: completed, todayHabitCount: count)
        }
        return HabitListView(viewModel: hvm)
    }
}

private struct MainTabPreview: View {
    let container: ModelContainer

    init() {
        let schema = Schema([
            User.self, Habit.self, Unit.self, Compliance.self,
            Origami.self, UserOrigami.self, OrigamiPhase.self, Quote.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        let container = try! ModelContainer(for: schema, configurations: [config])
        self.container = container

        let context = container.mainContext
        let user = User(name: "Antonio")
        context.insert(user)

        let origami = Origami(name: "mariposa", numberOfPhases: 5)
        context.insert(origami)
        for phase in 0..<5 {
            let op = OrigamiPhase(phaseNumber: phase, illustrationName: "flor_fase5")
            op.origami = origami
            context.insert(op)
        }
        let uo = UserOrigami()
        uo.user = user
        uo.origami = origami
        context.insert(uo)
    }

    var body: some View {
        MainTabView()
            .modelContainer(container)
    }
}

#Preview {
    MainTabPreview()
}
