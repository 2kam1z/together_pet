import FirebaseAuth
import SwiftUI

struct PairView: View {
    @Environment(AuthSession.self) private var session
    @Environment(PairSession.self) private var pairSession
    
    @State private var isLoading = false
    @State private var message = ""
    @State private var inviteCode = ""
    @State private var enteredInviteCode = ""
    @State private var checkedInvite: PairInvite?
    
    private var cleanedInviteCode: String {
        enteredInviteCode.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func createPair() async {
        guard let user = session.currentUser,
              !isLoading,
              !pairSession.isLoading,
              pairSession.pairID == nil,
              pairSession.errorMessage.isEmpty
        else {
            return
        }

        isLoading = true
        message = ""

        defer {
            isLoading = false
        }

        do {
            if let existingPair = try await PairService().findPairID(userID: user.uid) {
                let pair = try await PairService().loadPair(pairID: existingPair)
                message =
                    "Ваш питомец: \(pair.pet.emoji) \(pair.pet.name). Уровень: \(pair.pet.level)"
                return
            }
            let pairID = try await PairService().createPair(userID: user.uid)
            message = "Пара создана: \(pairID)"

            await pairSession.load(userID: user.uid)
        } catch {
            message = FirestoreErrorMessage.text(for: error)
        }
    }
    
    private func createInvite() async {
        guard !isLoading,
              let user = session.currentUser,
              let pairID = pairSession.pairID,
              let pair = pairSession.pair,
              pair.memberIDs.count == 1
        else {
            return
        }
        
        isLoading = true
        message = ""
        
        defer {
            isLoading = false
        }
        
        do {
            inviteCode = try await PairInviteService().createInvite(
                pairID: pairID,
                userID: user.uid
            )
        } catch {
            message = FirestoreErrorMessage.text(for: error)
        }
    }
    
    private func checkInvite() async {
        guard !isLoading,
              !cleanedInviteCode.isEmpty,
              let user = session.currentUser
        else {
            return
        }
        
        let code = cleanedInviteCode
        isLoading = true
        message = ""
        checkedInvite = nil
        
        defer {
            isLoading = false
        }
        
        do {
            let invite = try await PairInviteService().loadInvite(code: code)
            if invite.createdBy == user.uid {
                message = "Это ваше приглашение. Передайте код другому человеку."
                return
            } else {
                checkedInvite = invite
            }
        } catch {
            message = FirestoreErrorMessage.text(for: error)
        }
    }
    
    private func acceptInvite() async {
        guard !isLoading,
              !pairSession.isLoading,
              pairSession.pairID == nil,
              checkedInvite != nil,
              let user = session.currentUser
        else {
            return
        }
        
        let code = cleanedInviteCode
        isLoading = true
        message = ""
        
        defer {
            isLoading = false
        }
        
        do {
            _ = try await PairInviteService().acceptInvite(code: code, userID: user.uid)
            
            checkedInvite = nil
            enteredInviteCode = ""
            
            await pairSession.load(userID: user.uid)
            message = "Вы присоединились к паре."
        } catch {
            checkedInvite = nil
            message = FirestoreErrorMessage.text(for: error)
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if let user = session.currentUser {
                
                if pairSession.pairID == nil,
                   !pairSession.isLoading,
                   pairSession.errorMessage.isEmpty{
                    Button("Создать пару") {
                        Task {
                            await createPair()
                        }
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
                    Text(
                        "Ваш питомец: \(pair.pet.emoji) \(pair.pet.name). Уровень: \(pair.pet.level)"
                    )
                    
                    if pair.memberIDs.count == 1 {
                        Button("Создать приглашение") {
                            Task {
                                await createInvite()
                            }
                        }
                        
                        if !inviteCode.isEmpty {
                            Text("Код приглашения")
                            
                            Text(inviteCode)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                            
                            Text("Действует 24 часа")
                                .font(.caption)
                        }
                    } else {
                        Text("Вы уже вместе")
                    }
                }
                
                if pairSession.pairID == nil,
                   !pairSession.isLoading,
                   pairSession.errorMessage.isEmpty {
                    TextField("Код приглашения", text: $enteredInviteCode)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: enteredInviteCode) { _, _ in
                            checkedInvite = nil
                        }
                    
                    Button("Проверить приглашение") {
                        Task {
                            await checkInvite()
                        }
                    }
                    .disabled(cleanedInviteCode.isEmpty)
                    
                    if checkedInvite != nil {
                        Text("Приглашение найдено")
                        
                        Button("Присоединиться") {
                            Task {
                                await acceptInvite()
                            }
                        }
                    }
                }
                
                if isLoading {
                    ProgressView("Подождите...")
                }
                
                if !message.isEmpty {
                    Text(message)
                }
            }
        }
        .padding()
        .navigationTitle("Наша пара")
        .onChange(of: pairSession.pairID) {_, _ in
            inviteCode = ""
            checkedInvite = nil
            enteredInviteCode = ""
            message = ""
        }
        .disabled(isLoading)
    }
}
