import Foundation

@Observable
class GamificationViewModel {

    private let origamiRepository: OrigamiRepositoryProtocol

    private(set) var currentOrigami: UserOrigami?
    var lastError: String?

    // Porcentaje diario que se reparte entre los hábitos programados para hoy
    private let dailyPercentage = 3.0

    var progressPercentage: Double {
        currentOrigami?.progressPercentage ?? 0
    }

    /// Nombre de la ilustración correspondiente a la fase actual según el progreso
    var currentIllustrationName: String? {
        guard let userOrigami = currentOrigami,
              let origami = userOrigami.origami else { return nil }
        let totalPhases = origami.numberOfPhases
        guard totalPhases > 0 else { return nil }
        let phases = origami.phases.sorted { $0.phaseNumber < $1.phaseNumber }
        guard !phases.isEmpty else { return nil }
        let phaseIndex = min(
            Int(userOrigami.progressPercentage / (100.0 / Double(totalPhases))),
            totalPhases - 1
        )
        return phases[phaseIndex].illustrationName
    }

    init(origamiRepository: OrigamiRepositoryProtocol) {
        self.origamiRepository = origamiRepository
    }

    func loadOrigami() {
        do {
            currentOrigami = try origamiRepository.fetchCurrentUserOrigami()
        } catch {
            lastError = "No se pudo cargar el origami: \(error.localizedDescription)"
        }
    }

    // Actualiza el progreso del origami activo al completar/descompletar un hábito
    // Incremento por hábito = 3% / número de hábitos programados hoy
    func habitToggled(completed: Bool, todayHabitCount: Int) {
        guard todayHabitCount > 0, let origami = currentOrigami else { return }
        let delta = dailyPercentage / Double(todayHabitCount)
        if completed {
            origami.progressPercentage = min(origami.progressPercentage + delta, 100)
        } else {
            origami.progressPercentage = max(origami.progressPercentage - delta, 0)
        }
        save()
    }

    private func save() {
        do {
            try origamiRepository.saveChanges()
        } catch {
            lastError = "No se pudo guardar el progreso: \(error.localizedDescription)"
        }
    }
}
