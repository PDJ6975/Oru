import Foundation
import SwiftData

enum SampleDataFactory {

    struct BaseUnits {
        let min: Unit
        let km: Unit
        let pages: Unit
    }

    // MARK: - Unidades

    static func insertBaseUnits(into context: ModelContext) -> BaseUnits {
        let uds = Unit(name: "uds")
        let min = Unit(name: "min")
        let km = Unit(name: "km")
        let pages = Unit(name: "páginas")
        [uds, min, km, pages].forEach { context.insert($0) }
        return BaseUnits(min: min, km: km, pages: pages)
    }

    // MARK: - Usuario

    static func insertSampleUser(into context: ModelContext) -> User {
        let user = User(name: "Anto")
        context.insert(user)
        return user
    }

    // MARK: - Hábitos

    // Inserta los hábitos de muestra y los devuelve en orden:
    // [meditar, correr, leer, entrenar, journaling(archivado)]
    static func insertSampleHabits(
        units: BaseUnits,
        user: User,
        into context: ModelContext
    ) -> [Habit] {
        let cal = Calendar.current

        let meditar = Habit(
            icon: "🧘🏼", name: "Meditar", type: .boolean,
            scheduledDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
            note: "Antes de desayunar, en silencio",
            creationDate: cal.date(from: DateComponents(year: 2025, month: 6)) ?? .now
        )

        let correr = Habit(
            icon: "🏃🏼", name: "Correr", type: .quantity,
            scheduledDays: [.monday, .wednesday, .friday], dailyGoal: 5,
            note: "Por el parque con música",
            creationDate: cal.date(from: DateComponents(year: 2025, month: 9)) ?? .now
        )
        correr.unit = units.km

        let leer = Habit(
            icon: "📖", name: "Leer", type: .quantity,
            scheduledDays: Habit.Weekday.allCases, dailyGoal: 20,
            creationDate: cal.date(from: DateComponents(year: 2026, month: 1)) ?? .now
        )
        leer.unit = units.pages

        let entrenar = Habit(
            icon: "🏋🏼", name: "Entrenar", type: .quantity,
            scheduledDays: [.monday, .wednesday, .friday], dailyGoal: 45,
            creationDate: cal.date(from: DateComponents(year: 2026, month: 3)) ?? .now
        )
        entrenar.unit = units.min

        let journaling = Habit(
            icon: "✍🏼", name: "Journaling", type: .boolean,
            scheduledDays: [.monday, .wednesday, .friday],
            creationDate: cal.date(from: DateComponents(year: 2025, month: 4)) ?? .now
        )
        journaling.status = .archived
        journaling.archivedDate = cal.date(from: DateComponents(year: 2026, month: 8)) ?? .now

        let habits = [meditar, correr, leer, entrenar, journaling]
        habits.forEach {
            $0.user = user
            context.insert($0)
        }
        return habits
    }

    // MARK: - Compliances

    // Inserta compliances para todos los hábitos (activos y archivados).
    // `habits` debe ser el array devuelto por `insertSampleHabits`.
    static func insertCompliances(for habits: [Habit], into context: ModelContext) {
        insertActiveCompliances(habits: habits, into: context)
        insertArchivedCompliances(habits: habits, into: context)
    }

    private static func insertActiveCompliances(habits: [Habit], into context: ModelContext) {
        let cal = Calendar.current
        let meditar = habits[0]
        let correr = habits[1]
        let leer = habits[2]
        let entrenar = habits[3]

        // Meditar — 30 días recientes + 20 días del año anterior
        for off in 1...30 {
            let cmp = Compliance(
                date: cal.date(byAdding: .day, value: -off, to: .now) ?? .now,
                completed: true
            )
            cmp.habit = meditar
            context.insert(cmp)
        }
        for off in 0..<20 {
            let date = cal.date(from: DateComponents(year: 2025, month: 9, day: 1))
                .flatMap { cal.date(byAdding: .day, value: off, to: $0) } ?? .now
            let cmp = Compliance(date: date, completed: off % 3 != 0)
            cmp.habit = meditar
            context.insert(cmp)
        }

        // Correr — 15 días con cantidades
        for off in 1...15 {
            let cmp = Compliance(
                date: cal.date(byAdding: .day, value: -off, to: .now) ?? .now,
                completed: true, recordedAmount: Double.random(in: 3...8)
            )
            cmp.habit = correr
            context.insert(cmp)
        }

        // Leer — 20 días
        for off in 1...20 {
            let cmp = Compliance(
                date: cal.date(byAdding: .day, value: -off, to: .now) ?? .now,
                completed: off % 4 != 0, recordedAmount: Double(Int.random(in: 10...35))
            )
            cmp.habit = leer
            context.insert(cmp)
        }

        // Entrenar — 12 días con minutos (compatible con TimerView)
        for off in 1...12 {
            let cmp = Compliance(
                date: cal.date(byAdding: .day, value: -off, to: .now) ?? .now,
                completed: true, recordedAmount: Double(Int.random(in: 30...60))
            )
            cmp.habit = entrenar
            context.insert(cmp)
        }
    }

    private static func insertArchivedCompliances(habits: [Habit], into context: ModelContext) {
        let cal = Calendar.current
        let journaling = habits[4]

        // Journaling (archivado, boolean) — 40 días
        for off in 20...60 {
            let cmp = Compliance(
                date: cal.date(byAdding: .day, value: -off, to: .now) ?? .now,
                completed: off % 5 != 0
            )
            cmp.habit = journaling
            context.insert(cmp)
        }
    }

    // MARK: - Origamis

    private struct OrigamiSeed {
        let name: String
        let phases: Int
        let daysAgo: Int
        let completed: Bool
        let progressPercentage: Double
        let revealedPhase: Int
    }

    // Inserta origamis de muestra vinculados al usuario:
    // — mariposa y luna: completados (galería)
    // — flor: en progreso activo (~40%)
    static func insertOrigamis(user: User, into context: ModelContext) {
        let cal = Calendar.current

        let completedSeeds: [OrigamiSeed] = [
            OrigamiSeed(name: "mariposa", phases: 5, daysAgo: 45, completed: true,
                        progressPercentage: 100, revealedPhase: 4),
            OrigamiSeed(name: "luna", phases: 6, daysAgo: 20, completed: true,
                        progressPercentage: 100, revealedPhase: 5)
        ]

        for seed in completedSeeds {
            let origami = Origami(name: seed.name, numberOfPhases: seed.phases)
            context.insert(origami)
            for phase in 0..<seed.phases {
                let op = OrigamiPhase(phaseNumber: phase, illustrationName: "\(seed.name)_fase\(phase)")
                op.origami = origami
                context.insert(op)
            }

            let uo = UserOrigami()
            uo.user = user
            uo.origami = origami
            uo.completed = true
            uo.revealedPhase = seed.revealedPhase
            uo.progressPercentage = seed.progressPercentage
            uo.completionDate = cal.date(byAdding: .day, value: -seed.daysAgo, to: .now)
            context.insert(uo)
        }

        // Origami en progreso
        let flor = Origami(name: "flor", numberOfPhases: 6)
        context.insert(flor)
        for phase in 0..<6 {
            let op = OrigamiPhase(phaseNumber: phase, illustrationName: "flor_fase\(phase)")
            op.origami = flor
            context.insert(op)
        }

        let uoFlor = UserOrigami()
        uoFlor.user = user
        uoFlor.origami = flor
        uoFlor.completed = false
        uoFlor.revealedPhase = 2
        uoFlor.progressPercentage = 40
        context.insert(uoFlor)
    }

    // MARK: - Citas

    // Inserta una cita de muestra para que `fetchRandomQuote()` tenga contenido
    // durante los previews.
    static func insertSampleQuote(into context: ModelContext) {
        let quote = Quote(text: "Si no hay viento, habrá que remar", source: "Aristóteles")
        context.insert(quote)
    }

    // MARK: - Setup completo

    // Popula el contexto con todos los datos de muestra (usuario, unidades, hábitos,
    // compliances, origamis y citas). Punto de entrada principal para `SampleData`.
    static func populateFullContext(_ context: ModelContext) {
        let user = insertSampleUser(into: context)
        let units = insertBaseUnits(into: context)
        let habits = insertSampleHabits(units: units, user: user, into: context)
        insertCompliances(for: habits, into: context)
        insertOrigamis(user: user, into: context)
        insertSampleQuote(into: context)
    }
}
