import SwiftUI
import SwiftData

struct HomeView: View {

    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @State private var navigateToHabits = false
    @State private var gamificationVM: GamificationViewModel?

    private var userName: String {
        users.first?.name ?? ""
    }

    private func todayFormatted() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "EEEE, d 'de' MMMM"
        return formatter.string(from: .now).capitalized
    }

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hola, \(userName)!")
                            .oruGreeting()

                        Text(todayFormatted())
                            .oruDateSubtitle()
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()
            }

            VStack(spacing: 16) {
                Image(systemName: "checklist")
                    .foregroundStyle(Color.oruPrimary)
                    .frame(width: 50, height: 50)
                    .glassEffect(.regular.interactive())
                    .oruPulse { navigateToHabits = true }

                if let gvm = gamificationVM, gvm.currentOrigami != nil {
                    origamiProgressButton(progress: gvm.progressPercentage)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(24)
        }
        .navigationDestination(isPresented: $navigateToHabits) {
            makeHabitListView()
        }
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

    private func origamiProgressButton(progress: Double) -> some View {
        let lineWidth: CGFloat = 3
        let inset = lineWidth / 2

        return ZStack {
            Circle()
                .strokeBorder(Color.secondary.opacity(0.2), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress / 100)
                .stroke(Color.oruPrimary, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(inset)

            Text("\(Int(progress))%")
                .oruPillCircle()
                .foregroundStyle(Color.oruPrimary)
        }
        .frame(width: 50, height: 50)
        .glassEffect(.regular, in: .circle)
    }
}

private struct HomePreview: View {
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
        let origami = Origami(name: "Grulla", numberOfPhases: 5)
        context.insert(origami)
        let userOrigami = UserOrigami(progressPercentage: 42)
        userOrigami.origami = origami
        context.insert(userOrigami)
    }

    var body: some View {
        NavigationStack {
            HomeView()
        }
        .modelContainer(container)
    }
}

#Preview {
    HomePreview()
}
