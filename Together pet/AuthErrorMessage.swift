import FirebaseAuth
import Foundation

enum AuthErrorMessage {
    static func text(for error: Error) -> String {
        let nsError = error as NSError

        guard nsError.domain == AuthErrorDomain,
              let code = AuthErrorCode(rawValue: nsError.code)
        else {
            return error.localizedDescription
        }

        switch code {
        case .invalidEmail:
            return "Проверьте адрес электронной почты."
        case .invalidCredential, .wrongPassword, .userNotFound:
            return "Не удалось войти. Проверьте email и пароль."
        case .emailAlreadyInUse:
            return "Этот email уже зарегистрирован. Попробуйте войти."
        case .weakPassword:
            return "Пароль слишком простой. Используйте более длинный и сложный пароль."
        case .networkError:
            return "Не удалось связаться с сервером. Проверьте интернет."
        case .tooManyRequests:
            return "Слишком много попыток. Попробуйте позже."
        case .userDisabled:
            return "Этот аккаунт отключён."
        default:
            return "Не удалось выполнить действие с аккаунтом. Попробуйте снова."
        }
    }
}
