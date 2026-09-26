import SwiftData
import SwiftUI

struct ContentView: View {
  @AppStorage("petName") private var petName = "Пикси"
  @AppStorage("petEmoji") private var petEmoji = "🐣"
  @AppStorage("energy") private var energy = 0
  @AppStorage("petExperience") private var petExperience = 0
  @AppStorage("lastResetTimestamp") private var lastResetTimestamp = 0.0
  @AppStorage("streak") private var streak = 0
  @AppStorage("lastGoalCompletionTimestamp") private var lastGoalCompletionTimestamp = 0.0
  
  @State private var goalToDelete: Goal?
  @State private var showingDeleteConfirmation = false
  @State private var selectedGoal: Goal?
  @State private var editedGoalTitle = ""
  @State private var editedGoalReward = 1
  @State private var editedGoalDaily = true
  @State private var newGoalTitle = ""
  @State private var newGoalReward = 1
  @State private var newGoalDaily = true
  @State private var isPresented = false
  @Query private var goals: [Goal]
  @Environment(\.modelContext) private var modelContext
  @Environment(\.scenePhase) private var scenePhase
  private let petCost = 3
  private var canPet: Bool {
    energy >= petCost
  }
  private var completedGoalsCount: Int {
    goals.filter { $0.isCompleted }.count
  }
  private var remainingGoalsCount: Int {
    goals.count - completedGoalsCount
  }
  private var activeGoals: [Goal] {
    goals.filter { !$0.isCompleted }
  }
  private var completeGoals: [Goal] {
    goals.filter { $0.isCompleted }
  }
  private var petLevel: Int {
    petExperience / 5 + 1
  }
  private var visibleStreak: Int {
    if lastGoalCompletionTimestamp == 0 {
      return 0
    }
    
    let lastDate = Date(timeIntervalSince1970: lastGoalCompletionTimestamp)
    let calendar = Calendar.current
    
    if calendar.isDateInToday(lastDate) || calendar.isDateInYesterday(lastDate) {
      return streak
    }
    
    return 0
  }
  
  private func goalRow(_ goal: Goal) -> some View {
      VStack(alignment: .leading, spacing: 8) {
          HStack {
              Button(goal.isCompleted ? "✓ \(goal.title)" : goal.title) {
                  if !goal.isCompleted {
                      goal.isCompleted = true
                      energy += goal.reward
                      registerGoalCompletion()
                  }
              }.disabled(goal.isCompleted)
              
              Text(goal.isDaily ? "Ежедневно" : "Одноразовая")
          }
          HStack {
              Button("Изменить") {
                  editedGoalTitle = goal.title
                  editedGoalReward = goal.reward
                  editedGoalDaily = goal.isDaily
                  selectedGoal = goal
              }
              .disabled(goal.isCompleted)
              
              Button("Удалить", role: .destructive) {
                  goalToDelete = goal
                  showingDeleteConfirmation = true
              }
          }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(12)
      .background(RoundedRectangle(cornerRadius: 12)
        .fill(goal.isCompleted ? Color.gray.opacity(0.12) : Color.orange.opacity(0.12)))
  }
  
  private func resetGoalsIfNewDay() {
    if lastResetTimestamp == 0 {
      lastResetTimestamp = Date.now.timeIntervalSince1970
    }
    
    if !Calendar.current.isDateInToday(Date(timeIntervalSince1970: lastResetTimestamp)) {
      for goal in goals {
        if goal.isDaily {
          goal.isCompleted = false
        }
      }
      lastResetTimestamp = Date.now.timeIntervalSince1970
    }
  }
  
  private func clearNewGoal() {
    newGoalTitle = ""
    newGoalReward = 1
    newGoalDaily = true
  }
  
  private func registerGoalCompletion() {
    let lastDate = Date(timeIntervalSince1970: lastGoalCompletionTimestamp)
    let calendar = Calendar.current
    
    if lastGoalCompletionTimestamp != 0 && calendar.isDateInToday(lastDate) {
      return
    }
    
    if lastGoalCompletionTimestamp != 0 && calendar.isDateInYesterday(lastDate) {
      streak += 1
    } else {
      streak = 1
    }
    
    lastGoalCompletionTimestamp = Date.now.timeIntervalSince1970
  }
  
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 12) {
            PetOverView(name: petName,
                        emoji: petEmoji,
                        energy: energy,
                        streak: visibleStreak,
                        level: petLevel,
                        experience: petExperience,
                        canPet: canPet,
                        onPet: {
                            if canPet {
                                energy -= petCost
                                petExperience += 1
                            }
                        }
            )
            NavigationLink("Настройки питомца") {
            PetSettingsView(petName: $petName, petEmoji: $petEmoji)
            }
              Text("Выполнено целей: \(completedGoalsCount)/\(goals.count)")
              Text("Осталось целей: \(remainingGoalsCount)")
              
              if goals.isEmpty {
                Text("Нет целей")
              }
              
              Text("Активные")
              
              ForEach(activeGoals) { goal in
                goalRow(goal)
              }
              
              if !completeGoals.isEmpty {
                Text("Выполненные")
                
                ForEach(completeGoals) { goal in
                  goalRow(goal)
                }
              }
              
              Button("Новая цель") {
                isPresented = true
              }
              .sheet(isPresented: $isPresented){
                VStack {
                  TextField("Новая цель", text: $newGoalTitle)
                  Stepper("Награда: \(newGoalReward)", value: $newGoalReward, in: 1...5)
                  Toggle("Ежедневно", isOn: $newGoalDaily)
                  Button("Сохранить"){
                    let title = newGoalTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    let reward = newGoalReward
                    let daily = newGoalDaily
                    
                    if !title.isEmpty {
                      modelContext.insert(Goal(title: title, reward: reward, daily: daily))
                      clearNewGoal()
                      isPresented = false
                    }
                  }.disabled(newGoalTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                  
                  Button("Отмена"){
                    clearNewGoal()
                    isPresented = false
                  }
                }
                .padding()
              }
              
            }.padding(16)
          }
          .onAppear {
            resetGoalsIfNewDay()
          }
          .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
              resetGoalsIfNewDay()
            }
          }
          .sheet(item: $selectedGoal) { goal in
            VStack {
              TextField("Название цели", text: $editedGoalTitle)
              
              Stepper(
                "Награда: \(editedGoalReward)",
                value: $editedGoalReward,
                in: 1...5
              )
              
              Toggle("Ежедневно", isOn: $editedGoalDaily)
              
              Button("Сохранить") {
                let title = editedGoalTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                if !title.isEmpty {
                  goal.title = title
                  goal.reward = editedGoalReward
                  goal.isDaily = editedGoalDaily
                  selectedGoal = nil
                }
              }.disabled(editedGoalTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
              
              Button("Отмена") {
                selectedGoal = nil
              }
            }
            .padding()
          }
          .confirmationDialog(
            "Удалить цель?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
          ) {
            Button("Удалить", role: .destructive) {
              if let goal = goalToDelete {
                modelContext.delete(goal)
                goalToDelete = nil
              }
            }
            
            Button("Отмена", role: .cancel) {
              goalToDelete = nil
            }
          } message: {
            Text("Это действие нельзя отменить.")
      }
    }
  }
}

#Preview {
  ContentView()
    .modelContainer(for: Goal.self, inMemory: true)
}
