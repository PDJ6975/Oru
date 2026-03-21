import SwiftUI
import SwiftData

struct StatsView: View {

    var viewModel: StatsViewModel

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Mi Resumen General
                VStack(spacing: 18) {
                    Text("Mi Resumen General")
                        .oruSectionTitle()
                        .frame(maxWidth: .infinity, alignment: .leading)

                    metricCard(icon: "apple.meditate", label: "Tasa de cumplimiento", value: rateText)

                    LazyVGrid(columns: gridColumns, spacing: 18) {
                        metricCard(icon: "flame", label: "Racha actual", value: "\(viewModel.currentStreak) días")
                        metricCard(icon: "trophy", label: "Mejor racha", value: "\(viewModel.bestStreak) días")
                        metricCard(
                            icon: "checkmark.seal",
                            label: "Hábitos realizados",
                            value: "\(viewModel.habitsCompleted) hábitos"
                        )
                        metricCard(icon: "star", label: "Días perfectos", value: "\(viewModel.perfectDays) días")
                    }

                    Divider()
                }
            }
            .padding(.horizontal)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Button { changeYear(by: -1) } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 9, weight: .bold))
                            .oruAccentPrimary()
                    }
                    .disabled(!canGoBack)
                    .opacity(canGoBack ? 1 : 0)

                    HStack(spacing: 0) {
                        Text("Seguimiento Anual ")
                            .oruAccent()
                        Text(String(viewModel.selectedYear))
                            .oruAccentPrimary()
                    }

                    Button { changeYear(by: 1) } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                            .oruAccentPrimary()
                    }
                    .disabled(!canGoForward)
                    .opacity(canGoForward ? 1 : 0)
                }
                .fixedSize()
            }
        }
        .onAppear {
            viewModel.loadStats()
        }
    }

    // MARK: - Subvistas

    private var rateText: String {
        let rate = viewModel.complianceRate
        if rate == 0 { return "0 %" }
        if rate.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(rate)) %"
        }
        return String(format: "%.1f %%", rate)
    }

    private var canGoBack: Bool {
        guard let min = viewModel.availableYears.last else { return false }
        return viewModel.selectedYear > min
    }

    private var canGoForward: Bool {
        guard let max = viewModel.availableYears.first else { return false }
        return viewModel.selectedYear < max
    }

    private func changeYear(by delta: Int) {
        viewModel.selectedYear += delta
    }

    private func metricCard(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 21))
                .foregroundStyle(Color.oruPrimary)

            Text(value)
                .oruMetricValue()

            Text(label)
                .oruMetricLabel()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}

// MARK: - Preview

private struct StatsPreview: View {
    @State private var viewModel: StatsViewModel

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

        let meditar = Habit(
            icon: "🧘🏼",
            name: "Meditar",
            type: .boolean,
            scheduledDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
            creationDate: Calendar.current.date(from: DateComponents(year: 2025, month: 6)) ?? .now
        )
        context.insert(meditar)

        // Compliances del año actual
        for dayOffset in 1...30 {
            let compliance = Compliance(
                date: Calendar.current.date(byAdding: .day, value: -dayOffset, to: .now) ?? .now,
                completed: true
            )
            compliance.habit = meditar
            context.insert(compliance)
        }

        // Compliances del año anterior para que aparezcan las flechas
        for dayOffset in 0..<20 {
            let date = Calendar.current.date(
                from: DateComponents(year: 2025, month: 9, day: 1)
            ).flatMap {
                Calendar.current.date(byAdding: .day, value: dayOffset, to: $0)
            } ?? .now
            let compliance = Compliance(date: date, completed: dayOffset % 3 != 0)
            compliance.habit = meditar
            context.insert(compliance)
        }

        let repository = HabitRepository(modelContext: context)
        _viewModel = State(initialValue: StatsViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            StatsView(viewModel: viewModel)
        }
        .modelContainer(container)
    }
}

#Preview {
    StatsPreview()
}
