import Foundation
import SwiftData

@Model
final class Compliance {
    var date: Date
    var completed: Bool
    var recordedAmount: Double?

    var habit: Habit?

    init(
        date: Date,
        completed: Bool = false,
        recordedAmount: Double? = nil
    ) {
        self.date = date
        self.completed = completed
        self.recordedAmount = recordedAmount
    }
}
