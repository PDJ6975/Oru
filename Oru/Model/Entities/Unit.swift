import SwiftData

@Model
class Unit {
    var name: String = ""

    init(name: String = "") {
        self.name = name
    }
}
