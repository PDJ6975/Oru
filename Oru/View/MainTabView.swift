import SwiftUI
import SwiftData

struct MainTabView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var gamificationVM: GamificationViewModel?
    @State private var habitVM: HabitViewModel?
    @State private var statsVM: StatsViewModel?
    @State private var timerVM: TimerViewModel?

    var body: some View {
        TabView {
            Tab("Inicio", systemImage: "house") {
                NavigationStack {
                    if let habitVM {
                        HomeView(gamificationVM: $gamificationVM, habitVM: habitVM)
                    }
                }
                .oruDefaultTint()
            }

            Tab("Estadísticas", systemImage: "chart.bar") {
                NavigationStack {
                    if let statsVM {
                        StatsView(viewModel: statsVM)
                    }
                }
                .oruDefaultTint()
            }

            Tab("Temporizador", systemImage: "timer") {
                Group {
                    if let timerVM {
                        TimerView(viewModel: timerVM)
                    }
                }
                .oruDefaultTint()
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
                let hvm = HabitViewModel(
                    repository: HabitRepository(modelContext: modelContext)
                )
                hvm.onHabitChanged = { [weak gamificationVM] allCompleted in
                    gamificationVM?.updateDailyProgress(allCompleted: allCompleted)
                }
                habitVM = hvm
            }
            if statsVM == nil {
                statsVM = StatsViewModel(
                    repository: HabitRepository(modelContext: modelContext),
                    origamiRepository: OrigamiRepository(modelContext: modelContext)
                )
            }
            if timerVM == nil, let habitVM {
                let tvm = TimerViewModel(
                    repository: HabitRepository(modelContext: modelContext),
                    habitVM: habitVM
                )
                tvm.onSessionCompleted = { [weak gamificationVM] minutes in
                    gamificationVM?.applySessionBonus(durationMinutes: minutes)
                }
                timerVM = tvm
                Task { await tvm.recoverSessionIfNeeded() }
            }
        }
    }
}

#Preview(traits: .sampleData) {
    MainTabView()
}
