import SwiftUI
import SwiftData

@Observable
@MainActor
class WelcomeViewModel {
    var name = ""
    var errorMessage: String?

    private let repository: UserRepositoryProtocol

    init(repository: UserRepositoryProtocol) {
        self.repository = repository
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isNameValid: Bool {
        let length = trimmedName.count
        return length >= 2 && length <= 30
    }

    func registerUser() -> Bool {
        guard isNameValid else {
            errorMessage = trimmedName.count < 2
                ? "El nombre debe tener al menos 2 caracteres."
                : "El nombre no puede superar los 30 caracteres."
            return false
        }

        do {
            let user = User(name: trimmedName)
            try repository.addUser(user)
            errorMessage = nil
            return true
        } catch {
            errorMessage = "No se pudo guardar el nombre. Inténtalo de nuevo."
            return false
        }
    }
}
