import Foundation
import SwiftData

@MainActor
protocol UserRepositoryProtocol {
    // MARK: - User
    func fetchUser() throws -> User?
    func addUser(_ user: User) throws

    // MARK: - Quote
    func fetchRandomQuote() throws -> Quote?
    func seedQuotesIfNeeded() throws

    // MARK: - Persistencia
    func saveChanges() throws
}

@MainActor
final class UserRepository: UserRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - User

    func fetchUser() throws -> User? {
        let descriptor = FetchDescriptor<User>()
        return try modelContext.fetch(descriptor).first
    }

    func addUser(_ user: User) throws {
        modelContext.insert(user)
        try saveChanges()
    }

    // MARK: - Quote

    func fetchRandomQuote() throws -> Quote? {
        let descriptor = FetchDescriptor<Quote>()
        let quotes = try modelContext.fetch(descriptor)
        return quotes.randomElement()
    }

    func seedQuotesIfNeeded() throws {
        let descriptor = FetchDescriptor<Quote>()
        let existingTexts = Set(try modelContext.fetch(descriptor).map(\.text))

        let catalog: [(text: String, source: String)] = [
            ("Si no hay viento, habrá que remar", "Aristóteles"),
            ("Aquel que tiene un porqué para vivir puede soportar casi cualquier cómo", "Viktor Frankl"),
            ("Tus límites son solo las paredes que tú mismo construyes", "Anónimo"),
            ("No te detengas hasta que te sientas orgulloso", "Anónimo"),
            ("Todo lo que siempre has querido está al otro lado del miedo", "George Addair"),
            ("Hazlo con miedo, pero hazlo", "Anónimo"),
            ("Si puedes soñarlo, puedes hacerlo", "Walt Disney"),
            ("Somos lo que hacemos repetidamente", "Aristóteles"),
            ("Tu única competencia es la persona que fuiste ayer", "Anónimo"),
            ("Donde no hay lucha, no hay fuerza", "Oprah Winfrey")
        ]

        let newQuotes = catalog.filter { !existingTexts.contains($0.text) }
        guard !newQuotes.isEmpty else { return }

        for entry in newQuotes {
            modelContext.insert(Quote(text: entry.text, source: entry.source))
        }
        try saveChanges()
    }

    // MARK: - Persistencia

    func saveChanges() throws {
        try modelContext.save()
    }
}
