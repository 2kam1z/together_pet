import FirebaseFirestore

struct SharedGoalService {
    func createGoal(
        pairID: String,
        title: String,
        reward: Int,
        isDaily: Bool
    ) async throws -> String {
        let goal = SharedGoal(title: title, reward: reward, isDaily: isDaily)
        let document = Firestore.firestore()
            .collection("pairs")
            .document(pairID)
            .collection("goals")
            .document()

        let data = try Firestore.Encoder().encode(goal)
        try await document.setData(data)

        return document.documentID
    }
    
    func loadGoals(pairID: String) async throws -> [SharedGoal] {
        let snapshot = try await Firestore.firestore()
            .collection("pairs")
            .document(pairID)
            .collection("goals")
            .getDocuments(source: .server)
        
        let goals = try snapshot.documents.map { document in
            try document.data(as: SharedGoal.self)
        }
        
        return goals
    }
    
    func completeGoal(pairID: String, goalID: String) async throws {
        let database = Firestore.firestore()
        let pairReference = database.collection("pairs").document(pairID)
        let goalReference = pairReference.collection("goals").document(goalID)

        _ = try await database.runTransaction { transaction, errorPointer -> Any? in
            do {
                let snapshot = try transaction.getDocument(goalReference)
                let goal = try snapshot.data(as: SharedGoal.self)

                guard !goal.isCompleted(
                    on: Date.now,
                    calendar: GoalCalendar.moscow
                ) else { return nil }
                
                let pairSnapshot = try transaction.getDocument(pairReference)
                let pair = try pairSnapshot.data(as: SharedPair.self)
                
                let newStreak = pair.streakAfterCompletion(on: Date.now, calendar: GoalCalendar.moscow)

                transaction.updateData(
                    [
                        "isCompleted": true,
                        "lastCompletedAt": FieldValue.serverTimestamp()
                    ],
                    forDocument: goalReference
                )

                transaction.updateData(
                    [
                        "pet.energy": FieldValue.increment(Int64(goal.reward)),
                        "lastCompletedGoalID": goalID,
                        "streak": newStreak,
                        "lastGoalCompletedAt": FieldValue.serverTimestamp()
                    ],
                    forDocument: pairReference
                )

                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }
    
    func updateGoal(
        pairID: String,
        goalID: String,
        title: String,
        reward: Int,
        isDaily: Bool
    ) async throws {
        let database = Firestore.firestore()
        
        let goalReference = database
            .collection("pairs")
            .document(pairID)
            .collection("goals")
            .document(goalID)
        
        _ = try await database.runTransaction { transaction, errorPointer -> Any? in
            do {
                let snapshot = try transaction.getDocument(goalReference)
                let goal = try snapshot.data(as: SharedGoal.self)
                
                if goal.isCompleted {
                    throw NSError(
                        domain: "SharedGoalService",
                        code: 1,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "Цель уже выполнена. Изменить ее нельзя."
                        ]
                    )
                }
                
                transaction.updateData(
                    [
                        "title": title,
                        "reward": reward,
                        "isDaily": isDaily
                    ],
                    forDocument: goalReference
                )
                
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }
    
    func deleteGoal(pairID: String, goalID: String) async throws {
        let database = Firestore.firestore()
        let goalReference = database
            .collection("pairs")
            .document(pairID)
            .collection("goals")
            .document(goalID)
        
        try await goalReference.delete()
    }
}
