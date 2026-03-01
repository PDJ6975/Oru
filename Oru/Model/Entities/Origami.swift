import SwiftData

@Model
final class Origami {
    var name: String
    var numberOfPhases: Int

    @Relationship(deleteRule: .cascade, inverse: \OrigamiPhase.origami)
    var phases: [OrigamiPhase] = []

    @Relationship(deleteRule: .cascade, inverse: \UserOrigami.origami)
    var userOrigamis: [UserOrigami] = []

    init(name: String, numberOfPhases: Int) {
        self.name = name
        self.numberOfPhases = numberOfPhases
    }
}
