import SwiftData
import Foundation

@Model
class Transaction {
    var id: UUID
    var amount: Double
    var note: String
    var date: Date
    var createdAt: Date
    var type: TransactionType

    // Relationships
    var category: Category?
    var wallet: Wallet?
    var user: User?

    // Pocket relationship - for auto-allocation tracking
    var allocatedPocketID: UUID?
    var allocatedAmount: Double

    // For transfers between wallets
    var sourceWallet: Wallet?
    var destinationWallet: Wallet?
    var isTransfer: Bool

    // For receipt/attachment
    var receiptImageData: Data?

    init(amount: Double, note: String = "", date: Date, type: TransactionType, category: Category? = nil, wallet: Wallet? = nil, user: User? = nil, allocatedPocketID: UUID? = nil, allocatedAmount: Double = 0, sourceWallet: Wallet? = nil, destinationWallet: Wallet? = nil, isTransfer: Bool = false, receiptImageData: Data? = nil) {
        self.id = UUID()
        self.amount = amount
        self.note = note
        self.date = date
        self.type = type
        self.category = category
        self.wallet = wallet
        self.user = user
        self.allocatedPocketID = allocatedPocketID
        self.allocatedAmount = allocatedAmount
        self.sourceWallet = sourceWallet
        self.destinationWallet = destinationWallet
        self.isTransfer = isTransfer
        self.receiptImageData = receiptImageData
        self.createdAt = Date()
    }

    var isIncome: Bool { type == .income }
    var isExpense: Bool { type == .expense }

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "IDR"
        formatter.locale = Locale(identifier: "id_ID")
        formatter.currencySymbol = "Rp"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "Rp0"
    }

    var displayTitle: String {
        if isTransfer {
            if let source = sourceWallet, let dest = destinationWallet {
                return "\(source.name) → \(dest.name)"
            }
            return "Transfer"
        }
        return note.isEmpty ? (category?.name ?? "Transaksi") : note
    }

    var displayIcon: String {
        if isTransfer { return "arrow.left.arrow.right" }
        return category?.icon ?? "doc.text"
    }

    var displayColor: String {
        if isTransfer { return "#007AFF" }
        return category?.colorHex ?? "#8E8E93"
    }
}
