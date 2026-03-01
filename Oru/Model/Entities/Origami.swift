import SwiftData

@Model
class Origami {
    var name: String = ""

    init(name: String = "") {
        self.name = name
    }
}
