import FirebaseFirestore
import Foundation

enum FirestoreErrorMessage {
    static func text(for error: Error) -> String {
        let nsError = error as NSError

        guard nsError.domain == FirestoreErrorDomain,
              let code = FirestoreErrorCode.Code(rawValue: nsError.code)
        else {
            return error.localizedDescription
        }

        switch code {
        case .unavailable:
            return "Не удалось связаться с сервером. Проверьте интернет и попробуйте снова."
        case .deadlineExceeded:
            return "Сервер не ответил вовремя. Попробуйте снова."
        case .permissionDenied:
            return "Действие недоступно для этого аккаунта или текущего состояния данных."
        case .unauthenticated:
            return "Не удалось подтвердить вход. Войдите в аккаунт заново."
        default:
            return "Не удалось выполнить действие. Попробуйте снова."
        }
    }
}
