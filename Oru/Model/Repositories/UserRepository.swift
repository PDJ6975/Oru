import Foundation
import SwiftData

@MainActor
protocol UserRepositoryProtocol {
    // MARK: - User
    func fetchUser() throws -> User?
    func addUser(_ user: User) throws

    // MARK: - Quote
    func fetchRandomQuote() throws -> Quote?

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

    // MARK: - Persistencia

    func saveChanges() throws {
        try modelContext.save()
    }
}
