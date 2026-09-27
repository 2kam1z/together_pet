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
                let result = try await Auth.auth().createUser(withEmail: cleanedEmail, password: password)
                message = "Аккаунт создан: \(result.user.email ?? email)"
            case .signIn:
                let result = try await Auth.auth().signIn(withEmail: cleanedEmail, password: password)
                message = "Выполнен вход: \(result.user.email ?? email)"
            }
        } catch {
                message = error.localizedDescription
        }
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
            password = ""
            message = ""
        } catch {
            message = error.localizedDescription
        }
    }
    
    private func createPair() async {
        guard let user = session.currentUser, !isLoading else {
            return
        }
        
        isLoading = true
        message = ""
        
        defer {
            isLoading = false
        }
        
        do{
            if let existingPair = try await PairService().findPairID(userID: user.uid) {
                let pair = try await PairService().loadPair(pairID: existingPair)
                message = "Ваш питомец: \(pair.pet.emoji) \(pair.pet.name). Уровень: \(pair.pet.level)"
                return
            }
            let pairID = try await PairService().createPair(userID: user.uid)
            message = "Пара создана: \(pairID)"
                
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
                
                Button("Создать пару") {
                    Task {
                        await createPair()
                    }
                }
                
                Button("Загрузить пару") {
                    Task {
                        await pairSession.load(userID: user.uid)
                    }
                }
                .disabled(pairSession.isLoading)
                
                if pairSession.isLoading {
                    ProgressView("Загружаем пару...")
                } else if !pairSession.errorMessage.isEmpty {
                    Text(pairSession.errorMessage)
                } else if let pair = pairSession.pair {
                    Text("Ваш питомец: \(pair.pet.emoji) \(pair.pet.name). Уровень: \(pair.pet.level)")
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
