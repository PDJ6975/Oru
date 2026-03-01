import SwiftData

@Model
class Habit {
    var name: String = ""

    init(name: String = "") {
        self.name = name
    }
}
