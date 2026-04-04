import SwiftUI
import SwiftData

@Observable
@MainActor
class WelcomeViewModel {
    var name = ""
    var errorMessage: String?

    private let repository: UserRepositoryProtocol?
    private let origamiRepository: OrigamiRepositoryProtocol?

    init(repository: UserRepositoryProtocol? = nil, origamiRepository: OrigamiRepositoryProtocol? = nil) {
        self.repository = repository
        self.origamiRepository = origamiRepository
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
            try repository?.addUser(user)
            assignFirstOrigami(to: user)
            errorMessage = nil
            return true
        } catch {
            errorMessage = "No se pudo guardar el nombre. Inténtalo de nuevo."
            return false
        }
    }

    private func assignFirstOrigami(to user: User) {
        guard let origamiRepository,
              let origami = try? origamiRepository.fetchNextOrigami() else { return }
        let userOrigami = UserOrigami()
        userOrigami.user = user
        userOrigami.origami = origami
        try? origamiRepository.addUserOrigami(userOrigami)
    }
}
