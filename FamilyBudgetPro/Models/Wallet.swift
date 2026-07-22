import Foundation
import SwiftData

@Model
class Wallet {
    @Attribute(.unique) var id: UUID
    var name: String              // Custom name like "BCA Gaji" or "Dompet Cash"
    var type: String              // WalletType rawValue
    var bankCode: String?         // Kode bank dari IndonesianBank
    var accountNumber: String?    // Nomor rekening
    var balance: Double
    var icon: String
    var color: String
    var createdAt: Date
    var updatedAt: Date
    var user: User?
    var accountHolder: String?
    var sortOrder: Int
    var isArchived: Bool

    // ⭐ FAMILY SHARING FIELDS
    var familyCode: String?
    var firebaseUid: String?

    @Relationship(deleteRule: .cascade, inverse: \Transaction.wallet)
    var transactions: [Transaction]?

    init(
        name: String,
        type: WalletType,
        bankCode: String? = nil,
        accountNumber: String? = nil,
        balance: Double = 0,
        icon: String? = nil,
        colorHex: String = "4A90E2",
        user: User? = nil,
        accountHolder: String? = nil,
        sortOrder: Int = 0,
        familyCode: String? = nil,
        firebaseUid: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.type = type.rawValue
        self.bankCode = bankCode
        self.accountNumber = accountNumber
        self.balance = max(balance, 0)
        self.icon = icon ?? type.icon
        self.color = colorHex
        self.createdAt = Date()
        self.updatedAt = Date()
        self.user = user
        self.accountHolder = accountHolder
        self.sortOrder = sortOrder
        self.isArchived = false
        self.familyCode = familyCode
        self.firebaseUid = firebaseUid
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

    // Bank display name
    var bankDisplayName: String? {
        guard let code = bankCode else { return nil }
        return IndonesianBank.allCases.first(where: { $0.code == code })?.name
    }

    // Full display name
    var displayName: String {
        if let bankName = bankDisplayName {
            return "\(bankName) - \(name)"
        }
        return name
    }
}
