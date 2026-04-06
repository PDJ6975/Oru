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
private func makeUser() -> User {
    User(name: "Test")
}

@MainActor
private func makeVM(
    origamiName: String = "mariposa",
    phases: Int = 5,
    progress: Double = 0,
    revealedPhase: Int = 0,
    user: User? = nil,
    repo: MockOrigamiRepository? = nil
) -> (GamificationViewModel, MockOrigamiRepository) {
    let repo = repo ?? MockOrigamiRepository()
    let origami = makeOrigami(name: origamiName, phases: phases)
    repo.origamis.append(origami)

    let uo = UserOrigami(revealedPhase: revealedPhase, progressPercentage: progress)
    uo.origami = origami
    uo.user = user ?? makeUser()
    repo.userOrigamis.append(uo)

    let vm = GamificationViewModel(origamiRepository: repo)
    vm.loadOrigami()
    return (vm, repo)
}

// MARK: - Suite principal

@MainActor
@Suite(.serialized)
struct GamificationTests {

    // MARK: Umbrales de fases

    @Test func nextPhaseThreshold_calculatesCorrectly() {
        let (vm5, _) = makeVM(phases: 5)
        #expect(vm5.nextPhaseThreshold == 25.0)

        let (vm6, _) = makeVM(origamiName: "bailarina", phases: 6)
        #expect(vm6.nextPhaseThreshold == 20.0)
    }

    @Test func nextPhaseThreshold_lastPhaseRevealed_returnsNil() {
        let (vm, _) = makeVM(revealedPhase: 4)
        #expect(vm.nextPhaseThreshold == nil)
    }

    @Test func hasPendingReveal_atThreshold_true() {
        let (vm, _) = makeVM(progress: 25.0)
        #expect(vm.hasPendingReveal == true)
    }

    // MARK: Progreso diario

    @Test func updateDailyProgress_addsAndRemovesBonus() {
        let user = makeUser()
        let (vm, _) = makeVM(progress: 0, user: user)

        vm.updateDailyProgress(allCompleted: true)
        #expect(vm.progressPercentage == 3.0)

        vm.updateDailyProgress(allCompleted: false)
        #expect(vm.progressPercentage == 0.0)
    }

    @Test func updateDailyProgress_clampsAtCeiling() {
        let user = makeUser()
        let (vm, _) = makeVM(progress: 24.0, user: user)

        vm.updateDailyProgress(allCompleted: true) // +3% → techo 25%
        #expect(vm.progressPercentage == 25.0)
    }

    // MARK: Bonus de sesion

    @Test func applySessionBonus_appliesCorrectTier() {
        let (vm1, _) = makeVM(progress: 0)
        vm1.applySessionBonus(durationMinutes: 14)
        #expect(vm1.progressPercentage == 1.0)

        let (vm2, _) = makeVM(progress: 0)
        vm2.applySessionBonus(durationMinutes: 59)
        #expect(vm2.progressPercentage == 4.0)

        let (vm3, _) = makeVM(progress: 0)
        vm3.applySessionBonus(durationMinutes: 60)
        #expect(vm3.progressPercentage == 5.0)
    }

    @Test func applySessionBonus_clampsAtCeiling() {
        let (vm, _) = makeVM(progress: 23.0)

        vm.applySessionBonus(durationMinutes: 60) // +5% → techo 25%
        #expect(vm.progressPercentage == 25.0)
    }

    // MARK: Revelado de fases

    @Test func revealNextPhase_incrementsRevealedPhase() {
        let (vm, _) = makeVM(progress: 25.0)
        vm.revealNextPhase()
        #expect(vm.currentOrigami?.revealedPhase == 1)
    }

    @Test func revealNextPhase_unlocksProgressCeiling() {
        let (vm, _) = makeVM(progress: 25.0)
        vm.revealNextPhase()
        #expect(vm.nextPhaseThreshold == 50.0)
    }

    @Test func currentIllustrationName_matchesRevealedPhase() {
        let (vm, _) = makeVM(revealedPhase: 2)
        #expect(vm.currentIllustrationName == "mariposa_fase2")
    }

    @Test func nextIllustrationName_lastPhaseRevealed_returnsNil() {
        let (vm, _) = makeVM(revealedPhase: 4)
        #expect(vm.nextIllustrationName == nil)
    }

    // MARK: Completado del origami

    @Test func isOrigamiCompleted_lastPhaseAnd100_true() {
        let (vm, _) = makeVM(progress: 100.0, revealedPhase: 4)
        #expect(vm.isOrigamiCompleted == true)
    }

    @Test func isOrigamiCompleted_lastPhaseBelow100_false() {
        let (vm, _) = makeVM(progress: 80.0, revealedPhase: 4)
        #expect(vm.isOrigamiCompleted == false)
    }

    // MARK: Asignacion y reinicio

    @Test func completeAndAssignNext_marksCompletedAndAssignsNew() {
        let repo = MockOrigamiRepository()
        let luna = makeOrigami(name: "luna", phases: 6)
        repo.origamis.append(luna)

        let (vm, _) = makeVM(progress: 100.0, revealedPhase: 4, repo: repo)
        let old = vm.currentOrigami

        vm.completeAndAssignNext()

        #expect(old?.completed == true)
        #expect(old?.completionDate != nil)
        #expect(vm.currentOrigami !== old)
    }

    @Test func completeAndAssignNext_resetsProgress() {
        let repo = MockOrigamiRepository()
        let luna = makeOrigami(name: "luna", phases: 6)
        repo.origamis.append(luna)

        let (vm, _) = makeVM(progress: 100.0, revealedPhase: 4, repo: repo)

        vm.completeAndAssignNext()

        #expect(vm.currentOrigami?.progressPercentage == 0)
        #expect(vm.currentOrigami?.revealedPhase == 0)
    }

    @Test func completeAndAssignNext_noNext_clearsOrigami() {
        let (vm, _) = makeVM(progress: 100.0, revealedPhase: 4)
        vm.completeAndAssignNext()
        #expect(vm.currentOrigami == nil)
    }

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

    // MARK: Interaccion entre sistemas

    @Test func completeAndAssignNext_thenToggle_doesNotDoubleApplyBonus() {
        let repo = MockOrigamiRepository()
        let user = makeUser()
        let luna = makeOrigami(name: "luna", phases: 6)
        repo.origamis.append(luna)

        let (vm, _) = makeVM(progress: 0, user: user, repo: repo)

        // Aplica el bonus al origami actual
        vm.updateDailyProgress(allCompleted: true)
        #expect(vm.progressPercentage == 3.0)

        // Completa y asigna nuevo origami
        vm.completeAndAssignNext()
        #expect(vm.progressPercentage == 0.0)

        // Intenta aplicar el bonus de nuevo: ya fue aplicado hoy, no debe sumarse
        vm.updateDailyProgress(allCompleted: true)
        #expect(vm.progressPercentage == 0.0)

        // Revierte y vuelve a aplicar: solo cuenta una vez
        vm.updateDailyProgress(allCompleted: false)
        vm.updateDailyProgress(allCompleted: true)
        #expect(vm.progressPercentage == 3.0)
    }
}
