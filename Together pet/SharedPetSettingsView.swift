import SwiftUI

struct SharedPetSettingsView: View {
    let pairID: String
    @State private var name = ""
    @State private var emoji = "🐣"
    @State private var isSaving = false
    @State private var message = ""
    @Environment(PairSession.self) private var pairSession

    private var cleanedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func saveSettings() async {
        guard !isSaving && !cleanedName.isEmpty else { return }
        let savedName = cleanedName
        let savedEmoji = emoji
        isSaving = true
        message = ""

        defer {
            isSaving = false
        }

        do {
            try await PairService().updatePetSettings(
                pairID: pairID,
                name: savedName, emoji: savedEmoji)
            message = "Настройки сохранены"
        } catch {
            message = FirestoreErrorMessage.text(for: error)
        }
    }

    var body: some View {
        Form {
            Picker("Питомец", selection: $emoji) {
                Text("🐒").tag("🐒")
                Text("🐣").tag("🐣")
                Text("🐱").tag("🐱")
                Text("🐶").tag("🐶")
            }

            TextField("Новое имя", text: $name)

            Button("Сохранить") {
                Task {
                    await saveSettings()
                }
            }
            .disabled(cleanedName.isEmpty)

            if isSaving == true {
                ProgressView("Сохранение...")
            }

            if !message.isEmpty {
                Text(message)
            }
        }
        .navigationTitle("Общий питомец")
        .disabled(isSaving)
        .onAppear {
            if pairSession.pairID == pairID,
                let pair = pairSession.pair
            {
                name = pair.pet.name
                emoji = pair.pet.emoji
            }
        }
    }
}
