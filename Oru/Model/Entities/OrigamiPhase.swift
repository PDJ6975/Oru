import SwiftData

@Model
class OrigamiPhase {
    var name: String = ""

    init(name: String = "") {
        self.name = name
    }
}
