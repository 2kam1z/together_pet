import FirebaseFirestore
import Foundation

struct PairInviteService {
    
    func createInvite(pairID: String, userID: String) async throws -> String{
        let document = Firestore.firestore()
            .collection("pairInvites")
            .document()
        
        let invite = PairInvite(
            pairID: pairID,
            createdBy: userID,
            expiresAt: Date.now.addingTimeInterval(24 * 60 * 60)
        )
        
        let data = try Firestore.Encoder().encode(invite)
        
        try await document.setData(data)
        return document.documentID
    }
    
    func loadInvite(code: String) async throws -> PairInvite {
        guard code.range(
            of: "^[A-Za-z0-9]{20}$",
            options: .regularExpression
        ) != nil else {
            throw PairInviteError.notFound
        }
        
        let snapshot = try await Firestore.firestore()
            .collection("pairInvites")
            .document(code)
            .getDocument(source: .server)
        
        guard snapshot.exists else {
            throw PairInviteError.notFound
        }
        
        let invite = try snapshot.data(as: PairInvite.self)
        
        guard invite.isAvailable(on: Date.now) else {
            throw PairInviteError.unavailable
        }
        
        return invite
    }
    
    func acceptInvite(code: String, userID: String) async throws -> String {
        guard code.range(
            of: "^[A-Za-z0-9]{20}$",
            options: .regularExpression
        ) != nil else {
            throw PairInviteError.notFound
        }
        
        if try await PairService().findPairID(userID: userID) != nil {
            throw PairInviteError.alreadyInPair
        }
        
        let database = Firestore.firestore()
        let inviteReference = database.collection("pairInvites").document(code)
        
        let result = try await database.runTransaction {
            transaction, errorPointer -> Any? in
            
            do {
                let snapshot = try transaction.getDocument(inviteReference)

                guard snapshot.exists else {
                    throw PairInviteError.notFound
                }

                let invite = try snapshot.data(as: PairInvite.self)

                guard invite.isAvailable(on: Date.now) else {
                    throw PairInviteError.unavailable
                }

                guard invite.createdBy != userID else {
                    throw PairInviteError.ownInvite
                }

                let pairReference = database
                    .collection("pairs")
                    .document(invite.pairID)

                transaction.updateData(
                    ["acceptedBy": userID],
                    forDocument: inviteReference
                )

                transaction.updateData(
                    [
                        "memberIDs": FieldValue.arrayUnion([userID]),
                        "lastAcceptedInviteID": code
                    ],
                    forDocument: pairReference
                )

                return invite.pairID
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
        guard let pairID = result as? String else {
            throw PairInviteError.invalidResponse
        }

        return pairID
    }
    
}
