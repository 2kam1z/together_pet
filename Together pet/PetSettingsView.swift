import SwiftUI

struct PetSettingsView: View {
  @Binding var petName: String
  @Binding var petEmoji: String
  
  var body: some View {
    Form {
      Picker("Изменить эмодзи", selection: $petEmoji) {
        Text("🐒").tag("🐒")
        Text("🐣").tag("🐣")
        Text("🐱").tag("🐱")
        Text("🐶").tag("🐶")
      }
      
      TextField("Изменить имя", text: $petName)
    }
  }
}
