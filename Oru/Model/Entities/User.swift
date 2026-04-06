import Foundation
import SwiftData

@Model
final class User {
    var name: String
    var dailyBonusAppliedDate: Date?
    
    // Un borrado en cascada requiere definir la relación bidireccional con inverse
    @Relationship(deleteRule: .cascade, inverse: \Habit.user)
    var habits: [Habit] = []

    @Relationship(deleteRule: .cascade, inverse: \UserOrigami.user)
    var userOrigamis: [UserOrigami] = []

    init(name: String) {
        self.name = name
    }
}
