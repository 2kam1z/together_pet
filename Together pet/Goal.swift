import Foundation
import SwiftData

@Model final class Goal: Identifiable {
  var title: String
  var reward: Int
  var isCompleted = false
  var isDaily = true

  init(title: String, reward: Int, daily: Bool = true) {
    self.title = title
    self.reward = reward
    self.isDaily = daily
  }
}
