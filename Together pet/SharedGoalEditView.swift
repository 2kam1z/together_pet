import SwiftUI

struct SharedGoalEditView: View {
    let goal: SharedGoal
    let pairID: String
    
    @State private var title = ""
    @State private var reward = 1
    @State private var isDaily = true
    @State private var isSaving = false
    @State private var errorMessage = ""
    
    @Environment(\.dismiss) private var dismiss
    
    private var cleanedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func saveGoal() async {
        let newTitle = cleanedTitle
        guard !isSaving, !newTitle.isEmpty, let goalID = goal.id else { return }
        
        isSaving = true
        errorMessage = ""
        
        defer {
            isSaving = false
        }
        
        do {
            try await SharedGoalService().updateGoal(
                pairID: pairID,
                goalID: goalID,
                title: newTitle,
                reward: reward,
                isDaily: isDaily)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        
    }
    
    var body: some View {
        Form {
            TextField("Название", text: $title)
            Stepper("Награда: \(reward)", value: $reward, in: 1...5)
            Toggle("Ежедневно", isOn: $isDaily)
            
            Button("Сохранить") {
                Task {
                    await saveGoal()
                }
            }
            .disabled(cleanedTitle.isEmpty)
            
            if isSaving {
                ProgressView("Сохраняем...")
            }
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
            
            Button("Отмена") {
                dismiss()
            }
        }
        .disabled(isSaving)
        .interactiveDismissDisabled(isSaving)
        .onAppear {
            title = goal.title
            reward = goal.reward
            isDaily = goal.isDaily
        }
    }
}
