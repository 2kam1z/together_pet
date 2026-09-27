import SwiftData
import SwiftUI

@main struct MyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var session = AuthSession()
    @State private var pairSession = PairSession()

    var body: some Scene {
        WindowGroup {
            RootView()
            .environment(session)
            .environment(pairSession)
            .onAppear {
                session.startListening()
            }
            .onDisappear {
                session.stopListening()
            }
            .modelContainer(for: Goal.self)
        }
    }
}
