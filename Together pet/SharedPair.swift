import Foundation

struct SharedPair: Codable {
    var memberIDs: [String]
    var pet: SharedPet
    var streak: Int? = nil
    var lastGoalCompletedAt: Date? = nil
    
    func visibleStreak(on date: Date, calendar: Calendar) -> Int {
        guard let lastGoalCompletedAt else { return 0}
        
        let lastDay = calendar.startOfDay(for: lastGoalCompletedAt)
        let currentDay = calendar.startOfDay(for: date)
        
        let days = calendar.dateComponents(
            [.day],
            from: lastDay,
            to: currentDay
        ).day
        
        if days == 0 || days == 1 {
            return streak ?? 0
        } else {
            return 0
        }
    }
    
    func streakAfterCompletion(on date: Date, calendar: Calendar) -> Int {
        guard let lastGoalCompletedAt else { return 1}
        
        let lastDay = calendar.startOfDay(for: lastGoalCompletedAt)
        let currentDay = calendar.startOfDay(for: date)
        
        let days = calendar.dateComponents(
            [.day],
            from: lastDay, to: currentDay
        ).day
        
        if days == 0 {
            return max(streak ?? 0, 1)
        } else if days == 1 {
            return max(streak ?? 0, 0) + 1
        } else {
            return 1
        }
    }
}
