import Observation
import Foundation

@Observable
final class PairSession {
    var pairID: String?
    var pair: SharedPair?
    var isLoading = false
    var errorMessage = ""
    
    func load(userID: String) async {
        isLoading = true
        errorMessage = ""
        pairID = nil
        pair = nil
        
        defer {
            isLoading = false
        }
        
        do {
            guard let foundID = try await PairService().findPairID(userID: userID) else {
                return
            }
            let loadedPair = try await PairService().loadPair(pairID: foundID)
            
            pairID = foundID
            pair = loadedPair
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
