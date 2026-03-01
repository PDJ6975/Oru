import SwiftData

@Model
class Quote {
    var name: String = ""

    init(name: String = "") {
        self.name = name
    }
}
