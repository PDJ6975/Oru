import SwiftUI
import SwiftData

struct MainTabView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var gamificationVM: GamificationViewModel?
    @State private var habitVM: HabitViewModel?

    var body: some View {
        TabView {
            Tab("Inicio", systemImage: "house") {
                NavigationStack {
                    HomeView(gamificationVM: $gamificationVM)
                }
            }

            Tab("Hábitos", systemImage: "checklist") {
                NavigationStack {
                    if let habitVM {
                        HabitListView(viewModel: habitVM)
                    }
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
                TimerView(viewModel: TimerViewModel(
                    repository: HabitRepository(modelContext: modelContext)
                ))
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
            if habitVM == nil {
                habitVM = HabitViewModel(
                    repository: HabitRepository(modelContext: modelContext)
                )
            }
        }
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

        let mariposa = Origami(name: "flor", numberOfPhases: 5)
        context.insert(mariposa)
        for phase in 0..<6 {
            let op = OrigamiPhase(phaseNumber: phase, illustrationName: "flor_fase\(phase)")
            op.origami = mariposa
            context.insert(op)
        }

        let luna = Origami(name: "luna", numberOfPhases: 6)
        context.insert(luna)
        for phase in 0..<6 {
            let op = OrigamiPhase(phaseNumber: phase, illustrationName: "luna_fase\(phase)")
            op.origami = luna
            context.insert(op)
        }

        let uo = UserOrigami()
        uo.user = user
        uo.origami = mariposa
        uo.revealedPhase = 5
        uo.progressPercentage = 100
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
