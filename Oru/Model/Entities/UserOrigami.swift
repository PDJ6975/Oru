import Foundation
import SwiftData

@Model
final class UserOrigami {
    var currentPhase: Int
    var completed: Bool
    var completionDate: Date?
    var progressPercentage: Double

    var user: User?

    var origami: Origami?

    init(
        currentPhase: Int = 1,
        completed: Bool = false,
        completionDate: Date? = nil,
        progressPercentage: Double = 0.0
    ) {
        self.currentPhase = currentPhase
        self.completed = completed
        self.completionDate = completionDate
        self.progressPercentage = progressPercentage
    }
}
