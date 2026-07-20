import Foundation
import SwiftData

@Model
class Wallet {
    @Attribute(.unique) var id: UUID
    var name: String
    var type: String
    var balance: Double
    var icon: String
    var color: String
    var createdAt: Date
    var updatedAt: Date
    var user: User?
    var accountHolder: String?

    @Relationship(deleteRule: .cascade, inverse: \Transaction.wallet)
    var transactions: [Transaction]?

    init(name: String, type: WalletType, balance: Double = 0, icon: String = "wallet.bifold", colorHex: String = "4A90E2", user: User? = nil, accountHolder: String? = nil) {
        self.id = UUID()
        self.name = name
        self.type = type.rawValue
        self.balance = max(balance, 0)
        self.icon = icon
        self.color = colorHex
        self.createdAt = Date()
        self.updatedAt = Date()
        self.user = user
        self.accountHolder = accountHolder
    }

    // Computed property for safe display
    var safeBalance: Double {
        return max(balance, 0)
    }

    // Alias for colorHex (backward compatibility)
    var colorHex: String {
        get { color }
        set { color = newValue }
    }

    // WalletType computed property
    var walletType: WalletType {
        get { WalletType(rawValue: type) ?? .cash }
        set { type = newValue.rawValue }
    }
}
