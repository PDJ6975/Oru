import SwiftUI
import SwiftData

struct HomeView: View {

    @Query private var users: [User]
    @Binding var gamificationVM: GamificationViewModel?
    var illustrationOverride: String?

    @State private var revealingName: String?
    @State private var revealOpacity: Double = 0

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

                origamiImage
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

    private var breathingActive: Bool {
        (gamificationVM?.hasPendingReveal ?? false) && revealingName == nil
    }

    @ViewBuilder
    private var origamiImage: some View {
        let currentName = illustrationOverride ?? gamificationVM?.currentIllustrationName ?? "mariposa"

        ZStack {
            Image(currentName)
                .resizable()
                .scaledToFit()

            if let nextName = revealingName {
                Image(nextName)
                    .resizable()
                    .scaledToFit()
                    .opacity(revealOpacity)
            }
        }
        .scaleEffect(breathingActive ? 1.05 : 1.0)
        .animation(
            breathingActive
                ? .easeInOut(duration: 1.8).repeatForever(autoreverses: true)
                : .easeInOut(duration: 0.8),
            value: breathingActive
        )
        .onTapGesture {
            guard gamificationVM?.hasPendingReveal == true else { return }
            revealingName = gamificationVM?.nextIllustrationName
            withAnimation(.easeIn(duration: 2.5)) {
                revealOpacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                gamificationVM?.revealNextPhase()
                revealOpacity = 0
                revealingName = nil
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
        uo.progressPercentage = 0
        uo.revealedPhase = 0
        context.insert(uo)

        let repo = OrigamiRepository(modelContext: context)
        let gvm = GamificationViewModel(origamiRepository: repo)
        gvm.loadOrigami()
        _gamificationVM = State(initialValue: gvm)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HomeView(gamificationVM: $gamificationVM)

                VStack {
                    Spacer()
                    HStack(spacing: 16) {
                        Button("-5%") {
                            gamificationVM?.currentOrigami?.progressPercentage = max(
                                (gamificationVM?.progressPercentage ?? 0) - 5, 0
                            )
                        }
                        Button("+5%") {
                            let ceiling = gamificationVM?.nextPhaseThreshold ?? 100
                            gamificationVM?.currentOrigami?.progressPercentage = min(
                                (gamificationVM?.progressPercentage ?? 0) + 5, ceiling
                            )
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom, 80)
                }
            }
        }
        .modelContainer(container)
    }
}

#Preview { HomePreview() }
