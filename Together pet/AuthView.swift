import FirebaseAuth
import SwiftUI

enum AuthAction {
    case register
    case signIn
}

struct AuthView: View {
    enum AuthAction: Hashable {
        case register
        case signIn
    }
    
    @State private var email = ""
    @State private var password = ""
    @State private var message = ""
    @State private var isLoading = false
    @State private var selectedAction: AuthAction = .signIn
    @State private var passwordConfirmation = ""
    @Environment(AuthSession.self) private var session
    @Environment(PairSession.self) private var pairSession

    private var cleanedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var canSubmit: Bool {
        guard !cleanedEmail.isEmpty, !password.isEmpty else {
            return false
        }
        
        if selectedAction == .register {
            return password == passwordConfirmation
        }
        
        return true
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
            message = AuthErrorMessage.text(for: error)
        }
    }

    private func signOut() {
        do {
            try Auth.auth().signOut()
            pairSession.reset()
            password = ""
            message = ""
        } catch {
            message = AuthErrorMessage.text(for: error)
        }
    }
    
    private func resetPassword() async {
        guard !isLoading, !cleanedEmail.isEmpty else { return }
        
        let address = cleanedEmail
        isLoading = true
        message = ""
        
        defer {
            isLoading = false
        }
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: address)
            message = "Если аккаунт с этим email существует, вы получите письмо для смены пароля. Проверьте также папку «Спам»."
        } catch {
            let nsError = error as NSError
            
            if nsError.domain == AuthErrorDomain,
               nsError.code == AuthErrorCode.userNotFound.rawValue {
                message = "Если аккаунт с этим email существует, вы получите письмо для смены пароля. Проверьте также папку «Спам»."
            } else {
                message = AuthErrorMessage.text(for: error)
            }
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
                Picker("Режим", selection: $selectedAction) {
                    Text("Вход").tag(AuthAction.signIn)
                    Text("Регистрация").tag(AuthAction.register)
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedAction) { _, _ in
                    passwordConfirmation = ""
                    message = ""
                }
                
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField("Пароль", text: $password)
                
                if selectedAction == .register {
                    SecureField("Повторите пароль", text: $passwordConfirmation)
                    
                    if !passwordConfirmation.isEmpty,
                       password != passwordConfirmation {
                        Text("Пароли не совпадают.")
                            .foregroundStyle(.red)
                    }
                }

                Button(
                    selectedAction == .register ? "Зарегистрироваться" : "Войти"
                ) {
                    Task {
                        await authenticate(action: selectedAction)
                    }
                }
                .disabled(!canSubmit)
                
                if selectedAction == .signIn {
                    Button("Забыли пароль?") {
                        Task {
                            await resetPassword()
                        }
                    }
                    .disabled(cleanedEmail.isEmpty)
                }
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
