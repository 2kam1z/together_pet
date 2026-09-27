import FirebaseFirestore

struct PairService {
    func createPair(userID: String) async throws -> String {
        let pet = SharedPet(name: "Пикси", emoji: "🐣", energy: 0, experience: 0)
        let pair = SharedPair(memberIDs: [userID], pet: pet)
        
        let document = Firestore.firestore()
            .collection("pairs")
            .document()
        
        let data = try Firestore.Encoder().encode(pair)
        try await document.setData(data)
        
        return document.documentID
    }
    
    func findPairID(userID: String) async throws -> String? {
        let snapshot = try await Firestore.firestore()
            .collection("pairs")
            .whereField("memberIDs", arrayContains: userID)
            .limit(to: 1)
            .getDocuments(source: .server)
        
        return snapshot.documents.first?.documentID
    }
    
    func loadPair(pairID: String) async throws -> SharedPair {
        let snapshot = try await Firestore.firestore()
            .collection("pairs")
            .document(pairID)
            .getDocument(source: .server)
        
        return try snapshot.data(as: SharedPair.self)
    }
}
