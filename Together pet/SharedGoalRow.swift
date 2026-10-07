import SwiftUI

struct SharedGoalRow: View {
    let goal: SharedGoal
    let isCompletedToday: Bool
    let onComplete: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(goal.title)
            Text("Награда: \(goal.reward)")
            
            if goal.isDaily {
                Text("Ежедневно")
            } else {
                Text("Одноразово")
            }
            
            if isCompletedToday {
                Text("Выполнена")
            } else {
                Text("Не выполнена")
            }
            
            Button("Выполнить") {
                onComplete()
            }
            .disabled(isCompletedToday)
            
            Button("Изменить") {
                onEdit()
            }
            .disabled(goal.isCompleted)
            
            Button("Удалить", role: .destructive) {
                onDelete()
            }
            .disabled(goal.isCompleted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            isCompletedToday
            ? Color.gray.opacity(0.12)
            : Color.orange.opacity(0.12)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

