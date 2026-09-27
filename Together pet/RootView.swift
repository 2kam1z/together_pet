import SwiftUI

struct RootView: View {
    @Environment(AuthSession.self) private var session

    var body: some View {
        Group{
            if session.isCheckingAuth{
                ProgressView("Проверяем аккаунт...")
            } else if session.currentUser != nil {
                ContentView()
            } else {
                AuthView()
            }
        }
    }
}

#Preview {
    RootView()
        .environment(AuthSession())
        .environment(PairSession())
}
