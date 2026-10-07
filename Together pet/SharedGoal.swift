import FirebaseFirestore
import Foundation

struct SharedGoal: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var reward: Int
    var isDaily = true
    var isCompleted = false
    var lastCompletedAt: Date? = nil
    
    func isCompleted(on date: Date, calendar: Calendar) -> Bool {
        if isDaily == false {
            return isCompleted
        }
        
        guard let lastCompletedAt else {
            return isCompleted
        }
        
        return calendar.isDate(lastCompletedAt, inSameDayAs: date)
    }
}
