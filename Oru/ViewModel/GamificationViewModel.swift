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

    // Umbral de progreso para desbloquear la siguiente fase
    var nextPhaseThreshold: Double? {
        guard let userOrigami = currentOrigami,
              let origami = userOrigami.origami else { return nil }
        let totalPhases = origami.numberOfPhases
        guard totalPhases > 1 else { return nil }
        let nextPhase = userOrigami.revealedPhase + 1
        guard nextPhase < totalPhases else { return nil }
        return Double(nextPhase) * (100.0 / Double(totalPhases - 1))
    }

    // Indica si el usuario ha alcanzado el umbral y debe pulsar para avanzar
    var hasPendingReveal: Bool {
        guard let threshold = nextPhaseThreshold else { return false }
        return progressPercentage >= threshold
    }

    // Nombre de la ilustración basado en la fase revelada por el usuario
    var currentIllustrationName: String? {
        guard let userOrigami = currentOrigami,
              let origami = userOrigami.origami else { return nil }
        let phases = origami.phases.sorted { $0.phaseNumber < $1.phaseNumber }
        let index = min(userOrigami.revealedPhase, phases.count - 1)
        guard index >= 0, !phases.isEmpty else { return nil }
        return phases[index].illustrationName
    }

    // Nombre de la ilustración de la siguiente fase (para la transición)
    var nextIllustrationName: String? {
        guard let userOrigami = currentOrigami,
              let origami = userOrigami.origami else { return nil }
        let phases = origami.phases.sorted { $0.phaseNumber < $1.phaseNumber }
        let nextIndex = userOrigami.revealedPhase + 1
        guard nextIndex < phases.count else { return nil }
        return phases[nextIndex].illustrationName
    }

    // El origami está completado: última fase revelada y progreso al 100%
    var isOrigamiCompleted: Bool {
        guard let userOrigami = currentOrigami,
              let origami = userOrigami.origami else { return false }
        let lastPhase = origami.numberOfPhases - 1
        return userOrigami.revealedPhase >= lastPhase && userOrigami.progressPercentage >= 100
    }

    // Hay más origamis disponibles para asignar
    var hasNextOrigamiAvailable: Bool {
        (try? origamiRepository.fetchNextOrigami()) != nil
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
    // El progreso se congela al alcanzar el umbral de la siguiente fase
    func habitToggled(completed: Bool, todayHabitCount: Int) {
        guard todayHabitCount > 0, let userOrigami = currentOrigami else { return }
        let delta = dailyPercentage / Double(todayHabitCount)
        let ceiling = nextPhaseThreshold ?? 100.0
        if completed {
            userOrigami.progressPercentage = min(userOrigami.progressPercentage + delta, ceiling)
        } else {
            userOrigami.progressPercentage = max(userOrigami.progressPercentage - delta, 0)
        }
        save()
    }

    // Avanza a la siguiente fase cuando el usuario pulsa
    func revealNextPhase() {
        guard hasPendingReveal, let userOrigami = currentOrigami else { return }
        userOrigami.revealedPhase += 1
        save()
    }

    // Completa el origami actual y asigna uno nuevo aleatorio
    func completeAndAssignNext() {
        guard let userOrigami = currentOrigami else { return }
        userOrigami.completed = true
        userOrigami.completionDate = .now

        do {
            if let nextOrigami = try origamiRepository.fetchNextOrigami() {
                let newUserOrigami = UserOrigami()
                newUserOrigami.user = userOrigami.user
                newUserOrigami.origami = nextOrigami
                try origamiRepository.addUserOrigami(newUserOrigami)
                currentOrigami = newUserOrigami
            } else {
                currentOrigami = nil
            }
            try origamiRepository.saveChanges()
        } catch {
            lastError = "No se pudo asignar el siguiente origami: \(error.localizedDescription)"
        }
    }

    private func sessionBonusPercentage(for minutes: Int) -> Double {
        switch minutes {
        case ..<15:  return 1.0
        case 15..<30: return 2.0
        case 30..<45: return 3.0
        case 45..<60: return 4.0
        default:      return 5.0
        }
    }

    func applySessionBonus(durationMinutes: Int) {
        guard let userOrigami = currentOrigami else { return }
        let bonus = sessionBonusPercentage(for: durationMinutes)
        let ceiling = nextPhaseThreshold ?? 100.0
        userOrigami.progressPercentage = min(userOrigami.progressPercentage + bonus, ceiling)
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
