import FirebaseFirestore
import Foundation
import Observation

@Observable
final class SharedGoalsSession {
    var goals: [SharedGoal] = []
    var isLoading = false
    var errorMessage = ""

    private var loadID = UUID()
    private var goalsListener: ListenerRegistration?
    
    func reset() {
        loadID = UUID()
        goalsListener?.remove()
        goalsListener = nil
        goals = []
        errorMessage = ""
        isLoading = false
    }
    
    func load(pairID: String) async {
        reset()
        let currentLoadID = loadID
        isLoading = true
        
        defer {
            if currentLoadID == loadID {
                isLoading = false
            }
        }
        
        do {
            let loadedGoals = try await SharedGoalService().loadGoals(pairID: pairID)
            guard currentLoadID == loadID else { return }
            goals = loadedGoals
            startListening(pairID: pairID)
        } catch {
            guard currentLoadID == loadID else { return }
            errorMessage = error.localizedDescription
        }
    }
    
    private func startListening(pairID: String) {
        let currentLoadID = loadID
        
        goalsListener = Firestore.firestore()
            .collection("pairs")
            .document(pairID)
            .collection("goals")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self,
                    self.loadID == currentLoadID
                else { return }
                
                if let error = error {
                    self.goals = []
                    self.errorMessage = error.localizedDescription
                    return
                }

                guard let snapshot else { return }

                do {
                    let loadedGoals = try snapshot.documents.map { document in
                        try document.data(as: SharedGoal.self)
                    }
                    self.goals = loadedGoals
                    self.errorMessage = ""
                } catch {
                    self.goals = []
                    self.errorMessage = error.localizedDescription
                }
            }
    }
}
