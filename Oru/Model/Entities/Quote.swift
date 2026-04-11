import SwiftData

@Model
final class Quote {
    var text: String
    var source: String

    init(text: String, source: String) {
        self.text = text
        self.source = source
    }
}
