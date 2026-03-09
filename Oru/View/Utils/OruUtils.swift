import Foundation

extension Double {

    // Formatea sin decimales si es entero, con un decimal si no.
    // Ejemplo: 5.0 -> "5", 3.5 -> "3.5"
    var formatted: String {
        truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", self)
            : String(format: "%.1f", self)
    }

    // Formatea con unidad opcional: "5 km", "3.5 min", o solo "5".
    func formatted(unit: Unit?) -> String {
        unit.map { "\(formatted) \($0.name)" } ?? formatted
    }
}
