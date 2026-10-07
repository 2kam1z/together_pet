import SwiftUI

struct PetOverView: View {
    let name: String
    let emoji: String
    let energy: Int
    let streak: Int
    let level: Int
    let experience: Int
    let canPet: Bool
    var onPet: (() -> Void)? = nil
    private var stageName: String {
        switch level {
        case 1...2:
            return "Малыш"
        case 3...4:
            return "Исследователь"
        default:
            return "Верный друг"
        }
    }
    private var stageColor: Color {
        switch level {
        case 1...2:
            return Color.yellow
        case 3...4:
            return Color.orange
        default:
            return Color.green
        }
    }

    var body: some View {
        VStack {
            Text("Уровень \(level)")
            Text("\(experience % 5)/5")
            ProgressView(value: Double(experience % 5), total: 5.0).tint(stageColor)
            Text("Твоя серия: \(streak)")
            Text(emoji).font(.system(size: 72))
            Text(name).font(.title2.bold())
            Text(stageName)
            Text("Энергия: \(energy)")

            if let onPet = onPet {
                Button("Погладить питомца") {
                    onPet()
                }
                .disabled(!canPet)
                .buttonStyle(.borderedProminent)
                .tint(stageColor)

                if !canPet {
                    Text("Не хватает энергии")
                }
            }

        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(stageColor.opacity(0.12))
        )

    }
}

#Preview {
    PetOverView(
        name: "Пикси", emoji: "🐣", energy: 0, streak: 1, level: 1, experience: 0, canPet: false,
        onPet: {})
}
