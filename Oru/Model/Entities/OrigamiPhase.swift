import SwiftData

@Model
final class OrigamiPhase {
    var phaseNumber: Int
    var illustrationName: String

    var origami: Origami?

    init(phaseNumber: Int, illustrationName: String) {
        self.phaseNumber = phaseNumber
        self.illustrationName = illustrationName
    }
}
