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
            }

            Image(illustrationOverride ?? gamificationVM?.currentIllustrationName ?? "mariposa")
                .resizable()
                .scaledToFit()
                .padding(20)
                .offset(y: 100)

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
    let illustrationOverride: String

    init(illustration: String = "mariposa") {
        self.illustrationOverride = illustration
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
    }

    var body: some View {
        NavigationStack {
            HomeView(gamificationVM: .constant(nil), illustrationOverride: illustrationOverride)
        }
        .modelContainer(container)
    }
}

#Preview("Mariposa - Fase 0") { HomePreview(illustration: "mariposa_fase0") }
#Preview("Mariposa - Fase 1") { HomePreview(illustration: "mariposa_fase1") }
#Preview("Mariposa - Fase 2") { HomePreview(illustration: "mariposa_fase2") }
#Preview("Mariposa - Fase 3") { HomePreview(illustration: "mariposa_fase3") }
#Preview("Mariposa - Fase 4") { HomePreview(illustration: "mariposa_fase4") }
