import SwiftUI

struct ContentView: View {
    @AppStorage("petName") private var petName = "Пикси"
    @AppStorage("petEmoji") private var petEmoji = "🐣"
    
    @State private var energy = 0
    @State private var newGoalTitle = ""
    @State private var newGoalReward = 1
    @State private var goals: [Goal] = [
        Goal(title: "Выпить воду", reward: 2),
        Goal(title: "Прогуляться", reward: 3),
        Goal(title: "Почитать 10 минут", reward: 1),
    ]
    
    private let petCost = 3
    private var canPet: Bool {
        energy >= petCost
    }
    private var completedGoalsCount: Int {
        goals.filter { $0.isCompleted }.count
    }
    
    var body: some View {
        ScrollView{
            VStack(spacing: 12) {
                Text(petEmoji)
                Picker("Изменить эмодзи", selection: $petEmoji){
                    Text("🐒").tag("🐒")
                    Text("🐣").tag("🐣")
                    Text("🐱").tag("🐱")
                    Text("🐶").tag("🐶")
                }
                Text(petName)
                TextField("Изменить имя", text: $petName)
                Text("Энергия: \(energy)")
                Text("Выполнено целей: \(completedGoalsCount)/\(goals.count)")
                
                ForEach($goals) { $goal in
                    Button(goal.isCompleted ? "✓ \(goal.title)" : goal.title) {
                        if !goal.isCompleted{
                            goal.isCompleted = true
                            energy += goal.reward
                        }
                    }.disabled(goal.isCompleted)
                }
                
                Button("Погладить питомца") {
                    if canPet {
                        energy -= petCost
                    }
                }.disabled(!canPet)
                
                if !canPet {
                    Text("Не хватает энергии")
                }
                
                TextField("Новая цель", text: $newGoalTitle)
                Stepper("Награда: \(newGoalReward)", value: $newGoalReward, in: 1...5)
                Button("Добавить цель") {
                    let title = newGoalTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    let reward = newGoalReward
                    
                    if !title.isEmpty {
                        goals.append(Goal(title: title, reward: reward))
                        newGoalTitle = ""
                        newGoalReward = 1
                    }
                }.disabled(newGoalTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }.padding(16)
        }
    }
}

#Preview {
    ContentView()
}

