import FirebaseAuth
import Observation

@Observable
final class AuthSession {
    var currentUser: FirebaseAuth.User?
    var isCheckingAuth = true
    private var authListener: AuthStateDidChangeListenerHandle?

    func startListening() {
        guard authListener == nil else { return }

        isCheckingAuth = true

        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            self?.isCheckingAuth = false
        }
    }

    func stopListening() {
        if let listener = authListener {
            Auth.auth().removeStateDidChangeListener(listener)
            authListener = nil
        }
    }
}
