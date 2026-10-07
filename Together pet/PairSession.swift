import FirebaseFirestore
import Foundation
import Observation

@Observable
final class PairSession {
    var pairID: String?
    var pair: SharedPair?
    var isLoading = false
    var errorMessage = ""
    private var loadID = UUID()
    private var pairListener: ListenerRegistration?

    func load(userID: String) async {
        reset()
        let currentLoadID = loadID
        isLoading = true

        defer {
            if currentLoadID == loadID {
                isLoading = false
            }
        }

        do {
            guard let foundID = try await PairService().findPairID(userID: userID) else {
                return
            }

            let loadedPair = try await PairService().loadPair(pairID: foundID)
            guard currentLoadID == loadID else { return }

            pairID = foundID
            pair = loadedPair
            startListening(pairID: foundID)
        } catch {
            guard currentLoadID == loadID else { return }
            errorMessage = FirestoreErrorMessage.text(for: error)
        }
    }

    func reset() {
        loadID = UUID()
        pairListener?.remove()
        pairListener = nil
        pair = nil
        pairID = nil
        errorMessage = ""
        isLoading = false
    }

    private func startListening(pairID: String) {
        let currentLoadID = loadID

        pairListener = Firestore.firestore()
            .collection("pairs")
            .document(pairID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self,
                    self.loadID == currentLoadID
                else { return }

                if let error = error {
                    self.pair = nil
                    self.errorMessage = FirestoreErrorMessage.text(for: error)
                    return
                }

                guard let snapshot, snapshot.exists else {
                    self.pair = nil
                    self.errorMessage = "Документы пары не найдены"
                    return
                }

                do {
                    let loadedPair = try snapshot.data(as: SharedPair.self)
                    self.pair = loadedPair
                    self.errorMessage = ""
                } catch {
                    self.pair = nil
                    self.errorMessage = FirestoreErrorMessage.text(for: error)
                }
            }
    }
}
