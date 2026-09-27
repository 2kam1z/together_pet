struct SharedPet: Codable {
    var name: String
    var emoji: String
    var energy: Int
    var experience: Int
    var level: Int {
        experience / 5 + 1
    }
    
}
