import SwiftData
import Foundation

@Model
class PocketTransaction {
    var id: UUID
    var amount: Double
    var note: String
    var date: Date
    var isDeposit: Bool  // true = deposit, false = withdraw
    var createdAt: Date
    
    // Relationships
    var pocketID: UUID
    var walletID: UUID?
    
    init(amount: Double, note: String = "", date: Date, isDeposit: Bool, pocketID: UUID, walletID: UUID? = nil) {
        self.id = UUID()
        self.amount = amount
        self.note = note
        self.date = date
        self.isDeposit = isDeposit
        self.pocketID = pocketID
        self.walletID = walletID
        self.createdAt = Date()
    }
}
