import SwiftUI
import SwiftData

struct StatsView: View {

    var viewModel: StatsViewModel
    @State private var showAllHabits = false
    @State private var showRankingInfo = false
    @State private var showArchivedInfo = false
    @State private var selectedOrigami: UserOrigami?

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private let topCount = 3

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Tu Resumen General
                VStack(spacing: 18) {
                    Text("Tu Resumen General")
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

                // MARK: - Tus Rutinas Principales
                habitsSection

                // MARK: - Hábitos Archivados
                if !viewModel.archivedHabitStats.isEmpty {
                    Divider()
                    archivedSection
                }

                // MARK: - Galería de Origamis
                if !viewModel.completedOrigamis.isEmpty {
                    Divider()
                    origamiSection
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
                    .opacity(canGoBack ? 1 : 0) // se oculta y no se eliminan para que el título esté fijo

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

    private var visibleHabits: [StatsViewModel.HabitStats] {
        showAllHabits ? viewModel.habitStats : Array(viewModel.habitStats.prefix(topCount))
    }

    private var hasMoreHabits: Bool {
        viewModel.habitStats.count > topCount
    }

    private var habitsSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                Text("Tus Rutinas Principales")
                    .oruSectionTitle()

                Button { showRankingInfo.toggle() } label: {
                    Image(systemName: "questionmark")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.oruPrimary)
                        .padding(4)
                }
                .glassEffect(.regular, in: .circle)
                .popover(isPresented: $showRankingInfo, arrowEdge: .top) {
                    Text("Tus hábitos se ordenan según constancia y racha actual."
                         + " Cuantos más días completes y mayor sea tu racha,"
                         + " más arriba aparecerán 🙌🏻.")
                        .oruTip()
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: 240)
                        .padding()
                        .presentationCompactAdaptation(.popover)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if viewModel.habitStats.isEmpty {
                statsEmptyRow
            } else {
                ForEach(visibleHabits) { stat in
                    habitRow(stat)
                }
            }

            if hasMoreHabits {
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showAllHabits.toggle()
                        }
                    } label: {
                        Text(showAllHabits ? "Ver menos" : "Ver todos")
                            .oruExpandButton()
                            .foregroundStyle(Color.oruPrimary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 3)
                    }
                    .glassEffect(.regular, in: .capsule)
                }
            }
        }
    }

    private func habitRow(_ stat: StatsViewModel.HabitStats) -> some View {
        HStack(spacing: 12) {
            Text(stat.habit.icon)
                .font(.system(size: 24))
                .frame(width: 36)

            VStack(spacing: 6) {
                // Fila 1: nombre a la izquierda, métricas principales a la derecha
                HStack {
                    Text(stat.habit.name)
                        .oruTextPrimary()
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    HStack(spacing: 10) {
                        habitMetric(icon: "flame", value: "\(stat.currentStreak)")
                        habitMetric(icon: "trophy", value: "\(stat.bestStreak)")
                        habitMetric(icon: "checkmark.seal", value: "\(stat.totalCompleted)")
                    }
                }

                // Fila 2 (solo quantity): acumulado a la izquierda, media a la derecha
                if stat.totalAccumulated != nil || stat.dailyAverage != nil {
                    HStack {
                        if let total = stat.totalAccumulated {
                            Text("Total: \(total.formatted(unit: stat.habit.unit))")
                                .oruTextSecondary()
                        }

                        Spacer(minLength: 0)

                        if let avg = stat.dailyAverage {
                            Text("Media: \(avg.formatted(unit: stat.habit.unit))")
                                .oruTextSecondary()
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }

    private var statsEmptyRow: some View {
        HStack(spacing: 10) {
            Text("😬")
                .font(.system(size: 22))

            VStack(alignment: .leading, spacing: 4) {
                Text("Sin estadísticas aún")
                    .oruTextPrimary()

                Text("Registra hábitos para ver aquí tu progreso.")
                    .oruTextSecondary()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }

    // MARK: - Sección de hábitos archivados

    private var archivedSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                Text("Hábitos que te Definen")
                    .oruSectionTitle()

                Button { showArchivedInfo.toggle() } label: {
                    Image(systemName: "questionmark")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.oruPrimary)
                        .padding(4)
                }
                .glassEffect(.regular, in: .circle)
                .popover(isPresented: $showArchivedInfo, arrowEdge: .top) {
                    Text("Aquí se almacenan los hábitos consolidados"
                         + " que has archivado y que definen tu identidad 🌟.")
                        .oruTip()
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: 240)
                        .padding()
                        .presentationCompactAdaptation(.popover)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.archivedHabitStats.enumerated()), id: \.element.id) { idx, stat in
                    archivedRow(stat)

                    if idx < viewModel.archivedHabitStats.count - 1 {
                        Divider().padding(.horizontal, 14)
                    }
                }
            }
            .glassEffect(.regular, in: .rect(cornerRadius: 14))
        }
    }

    private func archivedRow(_ stat: StatsViewModel.HabitStats) -> some View {
        HStack(spacing: 12) {
            Text(stat.habit.icon)
                .font(.system(size: 22))
                .frame(width: 32)

            VStack(spacing: 6) {
                HStack {
                    Text(stat.habit.name)
                        .oruTextPrimary()
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    HStack(spacing: 10) {
                        habitMetric(icon: "trophy", value: "\(stat.bestStreak)")
                        habitMetric(icon: "checkmark.seal", value: "\(stat.totalCompleted)")
                    }
                }

                if stat.totalAccumulated != nil || stat.dailyAverage != nil {
                    HStack {
                        if let total = stat.totalAccumulated {
                            Text("Total: \(total.formatted(unit: stat.habit.unit))")
                                .oruTextSecondary()
                        }

                        Spacer(minLength: 0)

                        if let avg = stat.dailyAverage {
                            Text("Media: \(avg.formatted(unit: stat.habit.unit))")
                                .oruTextSecondary()
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Galería de origamis completados

    private var origamiSection: some View {
        VStack(spacing: 14) {
            Text("Tu Colección de Origamis")
                .oruSectionTitle()
                .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(viewModel.completedOrigamis, id: \.id) { uo in
                        origamiCard(uo)
                            .containerRelativeFrame(.horizontal, count: 2, spacing: 12)
                            .onTapGesture { selectedOrigami = uo }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
        }
        .sheet(item: $selectedOrigami) { uo in
            origamiDetail(uo)
        }
    }

    private func origamiCard(_ uo: UserOrigami) -> some View {
        VStack(spacing: 8) {
            Image(uo.lastPhaseIllustration ?? "mariposa")
                .resizable()
                .scaledToFit()
                .frame(height: 140)

            Text(uo.origami?.name.capitalized ?? "Origami")
                .oruTextPrimary()
                .lineLimit(1)

            Text(uo.completionDate?.formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "es_ES"))) ?? "Sin fecha")
                .oruTextSecondary()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }

    private func origamiDetail(_ uo: UserOrigami) -> some View {
        VStack(spacing: 16) {
            Spacer()

            Image(uo.lastPhaseIllustration ?? "mariposa")
                .resizable()
                .scaledToFit()
                .padding(.horizontal, 40)

            Text(uo.origami?.name.capitalized ?? "Origami")
                .oruSectionTitle()

            Text("Completado el \(uo.completionDate?.formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "es_ES"))) ?? "—")")
                .oruTextSecondary()

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func habitMetric(icon: String, value: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(Color.oruPrimary)
            Text(value)
                .oruExpandButton()
                .foregroundStyle(.secondary)
        }
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
        let (habits, units) = Self.sampleData()
        units.forEach { context.insert($0) }
        habits.forEach { context.insert($0) }
        Self.insertCompliances(habits: habits, into: context)
        Self.insertOrigamis(into: context)

        let repository = HabitRepository(modelContext: context)
        let origamiRepo = OrigamiRepository(modelContext: context)
        _viewModel = State(initialValue: StatsViewModel(
            repository: repository,
            origamiRepository: origamiRepo
        ))
    }

    var body: some View {
        NavigationStack {
            StatsView(viewModel: viewModel)
        }
        .modelContainer(container)
    }

    private static func sampleData() -> (habits: [Habit], units: [Unit]) {
        let cal = Calendar.current
        let km = Unit(name: "km")
        let paginas = Unit(name: "páginas")

        let meditar = Habit(
            icon: "🧘🏼", name: "Meditar", type: .boolean,
            scheduledDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
            creationDate: cal.date(from: DateComponents(year: 2025, month: 6)) ?? .now
        )
        let correr = Habit(
            icon: "🏃🏼", name: "Correr", type: .quantity,
            scheduledDays: [.monday, .wednesday, .friday], dailyGoal: 5,
            creationDate: cal.date(from: DateComponents(year: 2025, month: 9)) ?? .now
        )
        correr.unit = km
        let leer = Habit(
            icon: "📖", name: "Leer", type: .quantity,
            scheduledDays: Habit.Weekday.allCases, dailyGoal: 20,
            creationDate: cal.date(from: DateComponents(year: 2026, month: 1)) ?? .now
        )
        leer.unit = paginas
        let estirar = Habit(
            icon: "🤸🏼", name: "Estirar", type: .boolean,
            scheduledDays: [.tuesday, .thursday, .saturday],
            creationDate: cal.date(from: DateComponents(year: 2026, month: 2)) ?? .now
        )
        let nadar = Habit(
            icon: "🏊🏼", name: "Nadar", type: .quantity,
            scheduledDays: [.tuesday, .thursday], dailyGoal: 2,
            creationDate: cal.date(from: DateComponents(year: 2025, month: 3)) ?? .now
        )
        nadar.unit = km
        nadar.status = .archived
        nadar.archivedDate = cal.date(from: DateComponents(year: 2026, month: 6)) ?? .now
        let journaling = Habit(
            icon: "✍🏼", name: "Journaling", type: .boolean,
            scheduledDays: [.monday, .wednesday, .friday],
            creationDate: cal.date(from: DateComponents(year: 2025, month: 4)) ?? .now
        )
        journaling.status = .archived
        journaling.archivedDate = cal.date(from: DateComponents(year: 2026, month: 8)) ?? .now
        return ([meditar, correr, leer, estirar, nadar, journaling], [km, paginas])
    }

    private static func insertCompliances(habits: [Habit], into context: ModelContext) {
        insertActiveCompliances(habits: habits, into: context)
        insertArchivedCompliances(habits: habits, into: context)
    }

    private static func insertActiveCompliances(habits: [Habit], into context: ModelContext) {
        let cal = Calendar.current
        let meditar = habits[0]
        let correr = habits[1]
        let leer = habits[2]
        let estirar = habits[3]

        // Meditar - año actual (30 días) + año anterior (flechas)
        for off in 1...30 {
            let cmp = Compliance(
                date: cal.date(byAdding: .day, value: -off, to: .now) ?? .now, completed: true
            )
            cmp.habit = meditar; context.insert(cmp)
        }
        for off in 0..<20 {
            let date = cal.date(from: DateComponents(year: 2025, month: 9, day: 1))
                .flatMap { cal.date(byAdding: .day, value: off, to: $0) } ?? .now
            let cmp = Compliance(date: date, completed: off % 3 != 0)
            cmp.habit = meditar; context.insert(cmp)
        }
        // Correr - 15 días con cantidades
        for off in 1...15 {
            let cmp = Compliance(
                date: cal.date(byAdding: .day, value: -off, to: .now) ?? .now,
                completed: true, recordedAmount: Double.random(in: 3...8)
            )
            cmp.habit = correr; context.insert(cmp)
        }
        // Leer - 20 días
        for off in 1...20 {
            let cmp = Compliance(
                date: cal.date(byAdding: .day, value: -off, to: .now) ?? .now,
                completed: off % 4 != 0, recordedAmount: Double(Int.random(in: 10...35))
            )
            cmp.habit = leer; context.insert(cmp)
        }
        // Estirar - 10 días
        for off in 1...10 {
            let cmp = Compliance(
                date: cal.date(byAdding: .day, value: -off, to: .now) ?? .now,
                completed: off % 2 == 0
            )
            cmp.habit = estirar; context.insert(cmp)
        }
    }

    private static func insertArchivedCompliances(habits: [Habit], into context: ModelContext) {
        let cal = Calendar.current
        let nadar = habits[4]
        let journaling = habits[5]

        // Nadar (archivado, quantity) - 25 días
        for off in 30...55 {
            let cmp = Compliance(
                date: cal.date(byAdding: .day, value: -off, to: .now) ?? .now,
                completed: true, recordedAmount: Double.random(in: 1...4)
            )
            cmp.habit = nadar; context.insert(cmp)
        }
        // Journaling (archivado, boolean) - 40 días
        for off in 20...60 {
            let cmp = Compliance(
                date: cal.date(byAdding: .day, value: -off, to: .now) ?? .now,
                completed: off % 5 != 0
            )
            cmp.habit = journaling; context.insert(cmp)
        }
    }

    private struct OrigamiSeed {
        let name: String
        let phases: Int
        let daysAgo: Int
    }

    private static func insertOrigamis(into context: ModelContext) {
        let cal = Calendar.current
        let catalog: [OrigamiSeed] = [
            OrigamiSeed(name: "mariposa", phases: 5, daysAgo: 45),
            OrigamiSeed(name: "luna", phases: 6, daysAgo: 20),
            OrigamiSeed(name: "flor", phases: 6, daysAgo: 5)
        ]

        for entry in catalog {
            let origami = Origami(name: entry.name, numberOfPhases: entry.phases)
            context.insert(origami)
            for phase in 0..<entry.phases {
                let op = OrigamiPhase(
                    phaseNumber: phase,
                    illustrationName: "\(entry.name)_fase\(phase)"
                )
                op.origami = origami
                context.insert(op)
            }

            let uo = UserOrigami()
            uo.origami = origami
            uo.completed = true
            uo.revealedPhase = entry.phases - 1
            uo.progressPercentage = 100
            uo.completionDate = cal.date(byAdding: .day, value: -entry.daysAgo, to: .now)
            context.insert(uo)
        }
    }
}

#Preview {
    StatsPreview()
}
