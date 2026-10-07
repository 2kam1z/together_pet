import SwiftUI

struct ContentView: View {
    @State private var newGoalTitle = ""
    @State private var newGoalReward = 1
    @State private var newGoalDaily = true
    @State private var isPresented = false
    @State private var isPetting = false
    @State private var petError = ""
    @State private var isSavingGoal = false
    @State private var goalError = ""
    @State private var goalsSession = SharedGoalsSession()
    @State private var completingGoalID: String?
    @State private var completionError = ""
    @State private var selectedSharedGoal: SharedGoal?
    @State private var sharedGoalToDelete: SharedGoal?
    @State private var showingSharedDeleteConfirmation = false
    @State private var isDeletingGoal = false
    @State private var deletionError = ""
    @State private var currentDate = Date.now
    @Environment(\.scenePhase) private var scenePhase
    @Environment(PairSession.self) private var pairSession

    private let petCost = 3
    private let goalCalendar = GoalCalendar.moscow
    
    private var canPet: Bool {
        (pairSession.pair?.pet.energy ?? 0) >= petCost
    }
    
    private var activeSharedGoals: [SharedGoal] {
        goalsSession.goals.filter {
            !$0.isCompleted(on: currentDate, calendar: goalCalendar)
        }
    }
    
    private var completedSharedGoals: [SharedGoal] {
        goalsSession.goals.filter {
            $0.isCompleted(on: currentDate, calendar: goalCalendar)
        }
    }

    private func clearNewGoal() {
        newGoalTitle = ""
        newGoalReward = 1
        newGoalDaily = true
    }

    private func petSharedPet() async {
        guard !isPetting,
            canPet,
            let pairID = pairSession.pairID
        else { return }

        isPetting = true
        petError = ""

        defer {
            isPetting = false
        }

        do {
            try await PairService().petPet(pairID: pairID)
        } catch {
            petError = error.localizedDescription
        }
    }

    private func createSharedGoal() async {
        let title = newGoalTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !isSavingGoal,
            !title.isEmpty,
            let pairID = pairSession.pairID
        else { return }

        let reward = newGoalReward
        let daily = newGoalDaily

        isSavingGoal = true
        goalError = ""

        defer {
            isSavingGoal = false
        }

        do {
            _ = try await SharedGoalService().createGoal(
                pairID: pairID,
                title: title,
                reward: reward,
                isDaily: daily
            )

            clearNewGoal()
            isPresented = false
            
        } catch {
            goalError = error.localizedDescription
        }
    }
    
    private func completeSharedGoal(_ goal: SharedGoal) async {
        guard completingGoalID == nil,
            !isDeletingGoal,
              !goal.isCompleted(on: Date.now, calendar: goalCalendar),
            let goalID = goal.id,
            let pairID = pairSession.pairID
        else { return }
        
        completingGoalID = goalID
        completionError = ""
        
        defer {
            completingGoalID = nil
        }
        
        do {
            try await SharedGoalService().completeGoal(
                pairID: pairID,
                goalID: goalID
            )
        } catch {
            completionError = error.localizedDescription
        }
    }
    
    private func deleteSharedGoal(_ goal: SharedGoal) async {
        guard completingGoalID == nil,
              !goal.isCompleted,
              !isDeletingGoal,
              let goalID = goal.id,
              let pairID = pairSession.pairID
        else {return }
        
        isDeletingGoal = true
        deletionError = ""
        
        defer {
            isDeletingGoal = false
        }
        
        do {
            try await SharedGoalService().deleteGoal(pairID: pairID, goalID: goalID)
        } catch {
            deletionError = error.localizedDescription
        }
    }
    
    private func sharedGoalRow(_ goal: SharedGoal) -> some View {
        SharedGoalRow(
            goal: goal,
            isCompletedToday: goal.isCompleted(
                on: currentDate,
                calendar: goalCalendar
            ),
            onComplete: {
                Task {
                    await completeSharedGoal(goal)
                }
            },
            onEdit: {
                selectedSharedGoal = goal
            },
            onDelete: {
                sharedGoalToDelete = goal
                showingSharedDeleteConfirmation = true
            }
        )
        .disabled(completingGoalID != nil || isDeletingGoal)
    }
    
    private func refreshDateAtMidnight() async {
        while !Task.isCancelled {
            currentDate = Date.now
            
            let today = goalCalendar.startOfDay(for: currentDate)
            
            guard let nextMidnight = goalCalendar.date(
                byAdding: .day,
                value: 1,
                to: today
            ) else {
                return
            }
            
            let seconds = max(nextMidnight.timeIntervalSinceNow, 1)
            
            do{
                try await Task.sleep(for: .seconds(seconds))
            } catch {
                return
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if pairSession.isLoading {
                        ProgressView("Загружаем общего питомца...")
                    } else if !pairSession.errorMessage.isEmpty {
                        Text(pairSession.errorMessage)
                    } else if let pair = pairSession.pair {
                        PetOverView(
                            name: pair.pet.name,
                            emoji: pair.pet.emoji,
                            energy: pair.pet.energy,
                            streak: pair.visibleStreak(on: currentDate, calendar: goalCalendar),
                            level: pair.pet.level,
                            experience: pair.pet.experience,
                            canPet: canPet,
                            onPet: {
                                Task {
                                    await petSharedPet()
                                }
                            }
                        )
                        .disabled(isPetting)

                        if isPetting {
                            ProgressView("Гладим питомца")
                        }

                        if !petError.isEmpty {
                            Text(petError)
                                .foregroundStyle(.red)
                        }

                        if let pairID = pairSession.pairID {
                            NavigationLink("Настройки питомца") {
                                SharedPetSettingsView(pairID: pairID)
                            }
                        }
                    } else {
                        Text("Создайте пару на экране «Аккаунт»")
                    }

                    NavigationLink("Аккаунт") {
                        AuthView()
                    }
                    
                    if pairSession.pairID != nil {
                        Text("Общие цели")
                            .font(.headline)
                        
                        Text("Выполнено: \(completedSharedGoals.count) из \(goalsSession.goals.count)")
                        
                        if isDeletingGoal {
                            ProgressView("Удаляем цель...")
                        }
                        
                        if !deletionError.isEmpty {
                            Text(deletionError)
                                .foregroundStyle(.red)
                        }
                        
                        if completingGoalID != nil {
                            ProgressView("Выполняем цель...")
                        }
                        
                        if !completionError.isEmpty {
                            Text(completionError)
                                .foregroundStyle(.red)
                        }
                        
                        if goalsSession.isLoading {
                            ProgressView("Загружаем цели...")
                        } else if !goalsSession.errorMessage.isEmpty {
                            Text(goalsSession.errorMessage)
                                .foregroundStyle(.red)
                        } else if goalsSession.goals.isEmpty {
                            Text("Общих целей пока нет")
                        } else {
                            if !activeSharedGoals.isEmpty {
                                Text("Активные")
                                    .font(.headline)
                                
                                ForEach(activeSharedGoals) {goal in
                                    sharedGoalRow(goal)
                                }
                            }
                            
                            if !completedSharedGoals.isEmpty {
                                Text("Выполненные")
                                    .font(.headline)
                                
                                ForEach(completedSharedGoals) { goal in
                                    sharedGoalRow(goal)
                                }
                            }
                        }
                    }

                    Button("Новая цель") {
                        goalError = ""
                        isPresented = true
                    }
                    .disabled(pairSession.pairID == nil)
                    .sheet(isPresented: $isPresented) {
                        VStack {
                            TextField("Новая цель", text: $newGoalTitle)

                            Stepper("Награда: \(newGoalReward)", value: $newGoalReward, in: 1...5)

                            Toggle("Ежедневно", isOn: $newGoalDaily)

                            Button("Сохранить") {
                                Task {
                                    await createSharedGoal()
                                }
                            }.disabled(
                                newGoalTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            )

                            if isSavingGoal {
                                ProgressView("Сохраняем цель")
                            }

                            if !goalError.isEmpty {
                                Text(goalError)
                                    .foregroundStyle(.red)
                            }

                            Button("Отмена") {
                                clearNewGoal()
                                isPresented = false
                            }
                        }
                        .padding()
                        .disabled(isSavingGoal)
                        .interactiveDismissDisabled(isSavingGoal)
                    }

                }.padding(16)
            }
            .sheet(item: $selectedSharedGoal) { goal in
                if let pairID = pairSession.pairID {
                    SharedGoalEditView(goal: goal, pairID: pairID)
                }
            }
            .onAppear {
                currentDate = Date.now
            }
            .task(id: pairSession.pairID) {
                if let pairID = pairSession.pairID {
                    await goalsSession.load(pairID: pairID)
                } else {
                    goalsSession.reset()
                }
            }
            .task(id: scenePhase) {
                guard scenePhase == .active else {
                    return
                }
                
                await refreshDateAtMidnight()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    currentDate = Date.now
                }
            }
            .confirmationDialog(
                "Удалить общую цель?",
                isPresented: $showingSharedDeleteConfirmation,
                titleVisibility: .visible,
                presenting: sharedGoalToDelete
            ) { goal in
                Button("Удалить", role: .destructive) {
                    Task {
                        await deleteSharedGoal(goal)
                    }
                    sharedGoalToDelete = nil
                }

                Button("Отмена", role: .cancel) {
                    sharedGoalToDelete = nil
                }
            } message: { goal in
                Text("Удалить «\(goal.title)» для вас обоих? Это действие нельзя отменить.")
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthSession())
        .environment(PairSession())
}
