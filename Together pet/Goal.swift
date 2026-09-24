import Foundation
import SwiftData

@Model final class Goal: Identifiable {
    var title: String
    var reward: Int
    var isCompleted = false
    
    init(title: String, reward: Int) {
        self.title = title
        self.reward = reward
    }
}

