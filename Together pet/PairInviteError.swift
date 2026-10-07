import Foundation

enum PairInviteError: LocalizedError {
    case notFound
    case unavailable
    case ownInvite
    case alreadyInPair
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Приглашение не найдено. Проверьте код."
        case .unavailable:
            return "Приглашение истекло или уже использовано."
        case .ownInvite:
            return "Нельзя принять собственное приглашение."
        case .alreadyInPair:
            return "Вы уже состоите в паре."
        case .invalidResponse:
            return "Не удалось получить результат присоединения."
        }
    }
}
