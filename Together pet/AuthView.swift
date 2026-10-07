import FirebaseAuth
import SwiftUI

enum AuthAction {
    case register
    case signIn
}

struct AuthView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var message = ""
    @State private var isLoading = false
    @Environment(AuthSession.self) private var session
    @Environment(PairSession.self) private var pairSession

    private var cleanedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var canSubmit: Bool {
        !cleanedEmail.isEmpty && !password.isEmpty
    }

    private func authenticate(action: AuthAction) async {
        guard !isLoading && canSubmit else { return }

        isLoading = true
        message = ""

        defer {
            isLoading = false
        }

        do {
            switch action {
            case .register:
                let result = try await Auth.auth().createUser(
                    withEmail: cleanedEmail, password: password)
                message = "Аккаунт создан: \(result.user.email ?? email)"
            case .signIn:
                let result = try await Auth.auth().signIn(
                    withEmail: cleanedEmail, password: password)
                message = "Выполнен вход: \(result.user.email ?? email)"
            }
        } catch {
            message = error.localizedDescription
        }
    }

    private func signOut() {
        do {
            try Auth.auth().signOut()
            pairSession.reset()
            password = ""
            message = ""
        } catch {
            message = error.localizedDescription
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Аккаунт")
                .font(.title)

            if session.isCheckingAuth {
                ProgressView("Проверяем аккаунт...")
            } else if let user = session.currentUser {
                Text("Вы вошли: \(user.email ?? "Email не указан")")
                
                NavigationLink("Наша пара") {
                    PairView()
                }

                Button("Выйти") {
                    signOut()
                }
            } else {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField("Пароль", text: $password)

                Button("Зарегистрироваться") {
                    Task {
                        await authenticate(action: .register)
                    }
                }.disabled(!canSubmit)

                Button("Войти") {
                    Task {
                        await authenticate(action: .signIn)
                    }
                }.disabled(!canSubmit)
            }

            if isLoading {
                ProgressView("Подождите...")
            }

            if !message.isEmpty {
                Text(message)
            }
        }
        .padding()
        .disabled(isLoading)
    }
}
