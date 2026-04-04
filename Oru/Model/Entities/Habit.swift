import Foundation
import SwiftData

@Model
final class Habit {
    var icon: String
    var name: String
    var type: HabitType
    var scheduledDaysRaw: String
    var dailyGoal: Double?
    var note: String?
    var creationDate: Date
    var startDate: Date
    var status: HabitStatus
    var archivedDate: Date?

    var user: User?

    @Relationship(deleteRule: .nullify)
    var unit: Unit?

    @Relationship(deleteRule: .cascade, inverse: \Compliance.habit)
    var compliances: [Compliance] = []
    
    // Definimos una variable computada para guardar los días programados
    // para el hábito como un String
    var scheduledDays: [Weekday] {
        get {
            scheduledDaysRaw
                .split(separator: ",")
                .compactMap { Int($0) }
                .compactMap { Weekday(rawValue: $0) }
        }
        set {
            scheduledDaysRaw = newValue
                .map { String($0.rawValue) }
                .joined(separator: ",")
        }
    }

    init(
        icon: String,
        name: String,
        type: HabitType,
        scheduledDays: [Weekday],
        dailyGoal: Double? = nil,
        note: String? = nil,
        creationDate: Date = .now,
        startDate: Date = .now,
        status: HabitStatus = .active
    ) {
        self.icon = icon
        self.name = name
        self.type = type
        self.scheduledDaysRaw = "" // Se inicializa vacía primero y se modifica al final
        self.dailyGoal = dailyGoal
        self.note = note
        self.creationDate = creationDate
        self.startDate = startDate
        self.status = status
        self.scheduledDays = scheduledDays
    }
}

extension Habit {
    enum HabitType: String, Codable, CaseIterable {
        case boolean
        case quantity
    }

    enum HabitStatus: String, Codable, CaseIterable {
        case active
        case consolidated
        case archived
    }

    enum Weekday: Int, Codable, CaseIterable {
        case monday = 1
        case tuesday = 2
        case wednesday = 3
        case thursday = 4
        case friday = 5
        case saturday = 6
        case sunday = 7
    }

    static let maxNameLength = 20
    static let maxGoalLength = 5
    static let maxNoteLength = 200
    static let consolidationThreshold = 66

    func isGoalMet(_ amount: Double) -> Bool {
        if let goal = dailyGoal {
            return amount >= goal
        }
        return amount > 0
    }

    // Actualiza el estado según los días completados.
    // Devuelve `true` si el hábito acaba de consolidarse.
    @discardableResult
    func updateConsolidationStatus() -> Bool {
        let completedDays = compliances.filter(\.completed).count
        if completedDays >= Self.consolidationThreshold, status == .active {
            status = .consolidated
            return true
        } else if completedDays < Self.consolidationThreshold, status == .consolidated {
            status = .active
        }
        return false
    }
}
