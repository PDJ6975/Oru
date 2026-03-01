import SwiftData

@Model
class User {
    var name: String = ""

    init(name: String = "") {
        self.name = name
    }
}
