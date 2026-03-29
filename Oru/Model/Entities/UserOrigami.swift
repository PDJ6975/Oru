import Foundation
import SwiftData

@Model
final class UserOrigami {
    var revealedPhase: Int
    var completed: Bool
    var completionDate: Date?
    var progressPercentage: Double

    var user: User?

    var origami: Origami?

    init(
        revealedPhase: Int = 0,
        completed: Bool = false,
        completionDate: Date? = nil,
        progressPercentage: Double = 0.0
    ) {
        self.revealedPhase = revealedPhase
        self.completed = completed
        self.completionDate = completionDate
        self.progressPercentage = progressPercentage
    }
}
