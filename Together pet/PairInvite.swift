import Foundation

struct PairInvite: Codable {
    var pairID: String
    var createdBy: String
    var expiresAt: Date
    var acceptedBy: String? = nil
    
    func isAvailable(on date: Date) -> Bool {
        return acceptedBy == nil && date < expiresAt
    }
}
