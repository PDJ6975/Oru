import SwiftUI
import SwiftData

struct HomeView: View {

    @Query private var users: [User]
    @Binding var gamificationVM: GamificationViewModel?
    var illustrationOverride: String?

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

                Text("\"El único modo de hacer un gran trabajo es amar lo que haces.\"")
                    .font(.system(size: 18, weight: .ultraLight, design: .serif)).italic()
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(0.9)
                    .padding(.horizontal, 32)

                Spacer()

                Image(illustrationOverride ?? gamificationVM?.currentIllustrationName ?? "mariposa")
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
            }

            if let gvm = gamificationVM, gvm.currentOrigami != nil {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        origamiProgressButton(progress: gvm.progressPercentage)
                    }
                }
                .padding(24)
            }
        }
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
    @State private var gamificationVM: GamificationViewModel?

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
            let op = OrigamiPhase(phaseNumber: phase, illustrationName: "mariposa_fase\(phase)")
            op.origami = origami
            context.insert(op)
        }

        let uo = UserOrigami()
        uo.user = user
        uo.origami = origami
        uo.progressPercentage = 85
        context.insert(uo)

        let repo = OrigamiRepository(modelContext: context)
        let gvm = GamificationViewModel(origamiRepository: repo)
        gvm.loadOrigami()
        _gamificationVM = State(initialValue: gvm)
    }

    var body: some View {
        NavigationStack {
            HomeView(gamificationVM: $gamificationVM)
        }
        .modelContainer(container)
    }
}

#Preview { HomePreview() }
