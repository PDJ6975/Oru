import Testing
import Foundation
@testable import Oru

// MARK: - Helpers

@MainActor
private func makeOrigami(name: String, phases: Int) -> Origami {
    let origami = Origami(name: name, numberOfPhases: phases)
    for phase in 0..<phases {
        let op = OrigamiPhase(phaseNumber: phase, illustrationName: "\(name)_fase\(phase)")
        op.origami = origami
        origami.phases.append(op)
    }
    return origami
}

@MainActor
private func makeVM(
    origamiName: String = "mariposa",
    phases: Int = 5,
    progress: Double = 0,
    revealedPhase: Int = 0,
    repo: MockOrigamiRepository? = nil
) -> (GamificationViewModel, MockOrigamiRepository) {
    let repo = repo ?? MockOrigamiRepository()
    let origami = makeOrigami(name: origamiName, phases: phases)
    repo.origamis.append(origami)

    let uo = UserOrigami(revealedPhase: revealedPhase, progressPercentage: progress)
    uo.origami = origami
    repo.userOrigamis.append(uo)

    let vm = GamificationViewModel(origamiRepository: repo)
    vm.loadOrigami()
    return (vm, repo)
}

// MARK: - 1. Formula de progreso

@MainActor
@Suite(.serialized)
struct ProgressFormulaTests {

    // 3 habitos programados: delta = 3% / 3 = 1%
    @Test func habitToggled_completed_incrementsProgress() {
        let (vm, _) = makeVM()
        vm.habitToggled(completed: true, todayHabitCount: 3)
        #expect(vm.progressPercentage == 1.0)
    }

    // 5 habitos programados: delta = 3% / 5 = 0.6%
    @Test func habitToggled_completed_fiveHabits_incrementsCorrectly() {
        let (vm, _) = makeVM()
        vm.habitToggled(completed: true, todayHabitCount: 5)
        #expect(vm.progressPercentage == 0.6)
    }

    // 1 habito programado: delta = 3% / 1 = 3%
    @Test func habitToggled_singleHabit_incrementsFull3Percent() {
        let (vm, _) = makeVM()
        vm.habitToggled(completed: true, todayHabitCount: 1)
        #expect(vm.progressPercentage == 3.0)
    }

    // Completar 3 de 3 secuencialmente: 1% + 1% + 1% = 3%
    @Test func habitToggled_multipleToggles_accumulatesCorrectly() {
        let (vm, _) = makeVM()
        vm.habitToggled(completed: true, todayHabitCount: 3)
        vm.habitToggled(completed: true, todayHabitCount: 3)
        vm.habitToggled(completed: true, todayHabitCount: 3)
        #expect(vm.progressPercentage == 3.0)
    }

    // Descompletar reduce el progreso
    @Test func habitToggled_uncompleted_decrementsProgress() {
        let (vm, _) = makeVM(progress: 3.0)
        vm.habitToggled(completed: false, todayHabitCount: 3)
        #expect(vm.progressPercentage == 2.0)
    }

    // todayHabitCount = 0: guard para evitar division por cero
    @Test func habitToggled_zeroHabitCount_noChange() {
        let (vm, _) = makeVM(progress: 5.0)
        vm.habitToggled(completed: true, todayHabitCount: 0)
        #expect(vm.progressPercentage == 5.0)
    }
}

// MARK: - 2. Umbrales de fases

@MainActor
@Suite(.serialized)
struct PhaseThresholdTests {

    // Mariposa (5 fases, 4 transiciones): umbral fase 1 = 100/4 = 25%
    @Test func nextPhaseThreshold_fivePhases_returnsCorrect() {
        let (vm, _) = makeVM()
        #expect(vm.nextPhaseThreshold == 25.0)
    }

    // Origami de 6 fases (5 transiciones): umbral fase 1 = 100/5 = 20%
    @Test func nextPhaseThreshold_sixPhases_returnsCorrect() {
        let (vm, _) = makeVM(origamiName: "bailarina", phases: 6)
        #expect(vm.nextPhaseThreshold == 20.0)
    }

    // Ultima fase revelada: no hay siguiente umbral
    @Test func nextPhaseThreshold_lastPhaseRevealed_returnsNil() {
        let (vm, _) = makeVM(revealedPhase: 4)
        #expect(vm.nextPhaseThreshold == nil)
    }

    // Progreso se congela al alcanzar el umbral
    @Test func habitToggled_clampsAtThreshold() {
        let (vm, _) = makeVM(progress: 24.5)
        vm.habitToggled(completed: true, todayHabitCount: 1) // +3% -> clamp a 25%
        #expect(vm.progressPercentage == 25.0)
    }

    // Progreso en el umbral activa hasPendingReveal
    @Test func hasPendingReveal_atThreshold_true() {
        let (vm, _) = makeVM(progress: 25.0)
        #expect(vm.hasPendingReveal == true)
    }
}

// MARK: - 3. Revelado de fases

@MainActor
@Suite(.serialized)
struct PhaseRevealTests {

    // revealedPhase pasa de 0 a 1
    @Test func revealNextPhase_incrementsRevealedPhase() {
        let (vm, _) = makeVM(progress: 25.0)
        vm.revealNextPhase()
        #expect(vm.currentOrigami?.revealedPhase == 1)
    }

    // Sin umbral alcanzado, revealedPhase no cambia
    @Test func revealNextPhase_noPendingReveal_noChange() {
        let (vm, _) = makeVM(progress: 10.0)
        vm.revealNextPhase()
        #expect(vm.currentOrigami?.revealedPhase == 0)
    }

    // Tras revelar fase 1, el techo sube al siguiente umbral (50%)
    @Test func revealNextPhase_unlocksProgressCeiling() {
        let (vm, _) = makeVM(progress: 25.0)
        vm.revealNextPhase()
        #expect(vm.nextPhaseThreshold == 50.0)
    }

    // Fase 2 revelada -> ilustracion "mariposa_fase2"
    @Test func currentIllustrationName_matchesRevealedPhase() {
        let (vm, _) = makeVM(revealedPhase: 2)
        #expect(vm.currentIllustrationName == "mariposa_fase2")
    }

    // Ultima fase revelada -> no hay siguiente ilustracion
    @Test func nextIllustrationName_lastPhaseRevealed_returnsNil() {
        let (vm, _) = makeVM(revealedPhase: 4)
        #expect(vm.nextIllustrationName == nil)
    }
}

// MARK: - 4. Completado del origami

@MainActor
@Suite(.serialized)
struct OrigamiCompletionTests {

    // Ultima fase + 100% -> completado
    @Test func isOrigamiCompleted_lastPhaseAnd100_true() {
        let (vm, _) = makeVM(progress: 100.0, revealedPhase: 4)
        #expect(vm.isOrigamiCompleted == true)
    }

    // Ultima fase + 80% -> no completado
    @Test func isOrigamiCompleted_lastPhaseBelow100_false() {
        let (vm, _) = makeVM(progress: 80.0, revealedPhase: 4)
        #expect(vm.isOrigamiCompleted == false)
    }
}

// MARK: - 5. Asignacion aleatoria y reinicio

@MainActor
@Suite(.serialized)
struct AssignmentTests {

    // Marca completado con fecha
    @Test func completeAndAssignNext_marksCompleted() {
        let repo = MockOrigamiRepository()
        let luna = makeOrigami(name: "luna", phases: 6)
        repo.origamis.append(luna)

        let (vm, _) = makeVM(progress: 100.0, revealedPhase: 4, repo: repo)
        let old = vm.currentOrigami

        vm.completeAndAssignNext()

        #expect(old?.completed == true)
        #expect(old?.completionDate != nil)
    }

    // Asigna un nuevo UserOrigami
    @Test func completeAndAssignNext_assignsNewOrigami() {
        let repo = MockOrigamiRepository()
        let luna = makeOrigami(name: "luna", phases: 6)
        repo.origamis.append(luna)

        let (vm, _) = makeVM(progress: 100.0, revealedPhase: 4, repo: repo)
        let old = vm.currentOrigami

        vm.completeAndAssignNext()

        #expect(vm.currentOrigami !== old)
        #expect(vm.currentOrigami != nil)
    }

    // Nuevo origami empieza en 0% y fase 0
    @Test func completeAndAssignNext_resetsProgress() {
        let repo = MockOrigamiRepository()
        let luna = makeOrigami(name: "luna", phases: 6)
        repo.origamis.append(luna)

        let (vm, _) = makeVM(progress: 100.0, revealedPhase: 4, repo: repo)

        vm.completeAndAssignNext()

        #expect(vm.currentOrigami?.progressPercentage == 0)
        #expect(vm.currentOrigami?.revealedPhase == 0)
    }

    // Sin origamis disponibles -> currentOrigami = nil
    @Test func completeAndAssignNext_noNext_clearsOrigami() {
        let (vm, _) = makeVM(progress: 100.0, revealedPhase: 4)

        vm.completeAndAssignNext()

        #expect(vm.currentOrigami == nil)
    }

    // El nuevo origami no es uno que el usuario ya tenga
    @Test func completeAndAssignNext_doesNotAssignAlreadyOwned() {
        let repo = MockOrigamiRepository()
        let luna = makeOrigami(name: "luna", phases: 6)
        let flor = makeOrigami(name: "flor", phases: 6)
        repo.origamis.append(luna)
        repo.origamis.append(flor)

        let (vm, _) = makeVM(progress: 100.0, revealedPhase: 4, repo: repo)

        vm.completeAndAssignNext()

        let assignedNames = repo.userOrigamis.compactMap { $0.origami?.name }
        let uniqueNames = Set(assignedNames)
        #expect(assignedNames.count == uniqueNames.count)
    }
}

// MARK: - 6. Carga

@MainActor
@Suite(.serialized)
struct LoadTests {

    // Carga el UserOrigami no completado
    @Test func loadOrigami_setsCurrentOrigami() {
        let repo = MockOrigamiRepository()
        let origami = makeOrigami(name: "mariposa", phases: 5)
        repo.origamis.append(origami)

        let uo = UserOrigami(progressPercentage: 10.0)
        uo.origami = origami
        repo.userOrigamis.append(uo)

        let vm = GamificationViewModel(origamiRepository: repo)
        #expect(vm.currentOrigami == nil)

        vm.loadOrigami()

        #expect(vm.currentOrigami === uo)
        #expect(vm.progressPercentage == 10.0)
    }
}
