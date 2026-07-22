import SwiftData
import Foundation

// MARK: - Pocket Auto Allocation Helper
struct PocketAutoAllocation {

    /// Auto-allocate income to all active pockets based on their allocation percentage
    /// Returns total allocated amount
    static func allocateIncome(
        amount: Double,
        to pockets: [Pocket],
        using wallets: [Wallet],
        in context: ModelContext
    ) -> Double {
        var totalAllocated: Double = 0

        for pocket in pockets {
            guard pocket.allocationPercentage > 0 else { continue }
            guard let walletID = pocket.walletID else { continue }
            guard let wallet = wallets.first(where: { $0.id == walletID }) else { continue }

            let allocationAmount = amount * (pocket.allocationPercentage / 100.0)

            // Only allocate if wallet has enough balance
            guard wallet.balance >= allocationAmount else { continue }

            // Deduct from wallet
            wallet.balance -= allocationAmount
            wallet.updatedAt = Date()

            // Add to pocket
            pocket.balance += allocationAmount

            totalAllocated += allocationAmount
        }

        try? context.save()
        return totalAllocated
    }

    /// Allocate to a specific pocket manually
    static func allocateToPocket(
        amount: Double,
        pocket: Pocket,
        wallets: [Wallet],
        in context: ModelContext
    ) -> Bool {
        guard let walletID = pocket.walletID else { return false }
        guard let wallet = wallets.first(where: { $0.id == walletID }) else { return false }
        guard wallet.balance >= amount else { return false }

        wallet.balance -= amount
        wallet.updatedAt = Date()
        pocket.balance += amount

        try? context.save()
        return true
    }

    /// Withdraw from pocket back to wallet
    static func withdrawFromPocket(
        amount: Double,
        from pocket: Pocket,
        wallets: [Wallet],
        in context: ModelContext
    ) -> Bool {
        guard pocket.balance >= amount else { return false }
        guard let walletID = pocket.walletID else { return false }
        guard let wallet = wallets.first(where: { $0.id == walletID }) else { return false }

        pocket.balance -= amount
        wallet.balance += amount
        wallet.updatedAt = Date()

        try? context.save()
        return true
    }

    /// Withdraw all balance from pocket back to wallet
    static func withdrawAllFromPocket(
        pocket: Pocket,
        wallets: [Wallet],
        in context: ModelContext
    ) -> Bool {
        guard pocket.balance > 0 else { return false }
        guard let walletID = pocket.walletID else { return false }
        guard let wallet = wallets.first(where: { $0.id == walletID }) else { return false }

        wallet.balance += pocket.balance
        wallet.updatedAt = Date()
        pocket.balance = 0

        try? context.save()
        return true
    }
}
