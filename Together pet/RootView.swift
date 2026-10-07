import FirebaseAuth
import SwiftUI

struct RootView: View {
    @Environment(AuthSession.self) private var session
    @Environment(PairSession.self) private var pairSession

    var body: some View {
        Group {
            if session.isCheckingAuth {
                ProgressView("Проверяем аккаунт...")
            } else if session.currentUser != nil {
                ContentView()
            } else {
                AuthView()
            }
        }
        .task(id: session.currentUser?.uid) {
            if let user = session.currentUser {
                await pairSession.load(userID: user.uid)
            } else {
                pairSession.reset()
            }
        }
    }
}

#Preview {
    RootView()
        .environment(AuthSession())
        .environment(PairSession())
}
