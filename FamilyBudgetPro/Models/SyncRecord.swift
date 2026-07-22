import Foundation
import SwiftData

@Model
class SyncRecord {
    var id: UUID
    var entityType: String      // "Transaction", "Wallet", "Category", dll
    var entityId: UUID
    var action: String          // "created", "updated", "deleted"
    var timestamp: Date
    var syncedToFirebase: Bool
    var firebaseUserId: String?
    
    init(entityType: String, entityId: UUID, action: String, firebaseUserId: String? = nil) {
        self.id = UUID()
        self.entityType = entityType
        self.entityId = entityId
        self.action = action
        self.timestamp = Date()
        self.syncedToFirebase = false
        self.firebaseUserId = firebaseUserId
    }
}
