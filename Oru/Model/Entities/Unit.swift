import SwiftData

@Model
final class Unit {
    var name: String
    var origin: UnitOrigin

    init(name: String, origin: UnitOrigin = .base) {
        self.name = name
        self.origin = origin
    }
}

extension Unit {
    enum UnitOrigin: String, Codable, CaseIterable {
        case base
        case custom
    }
}
