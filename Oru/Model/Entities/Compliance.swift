import SwiftData

@Model
class Compliance {
    var name: String = ""

    init(name: String = "") {
        self.name = name
    }
}
