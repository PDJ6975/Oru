import SwiftData

@Model
class UserOrigami {
    var name: String = ""

    init(name: String = "") {
        self.name = name
    }
}
