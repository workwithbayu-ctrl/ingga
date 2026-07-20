import Foundation
import SwiftData
import Combine
import FirebaseAuth
import FirebaseFirestore

@Observable
class DataService: ObservableObject {
    static let shared = DataService()

    var modelContext: ModelContext?
    var modelContainer: ModelContainer?
    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()

    private init() {
        print("🚀 DataService initialized (container will be set from app)")
    }

    func setModelContainer(_ container: ModelContainer) {
        self.modelContainer = container
        // ✅ FIX: Use mainContext instead of creating new context
        self.modelContext = container.mainContext
        print("✅ DataService container set - using mainContext")
    }

    // MARK: - Startup Cleanup (Fix negative balances)
    func fixNegativeBalances() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<Wallet>()
        do {
            let wallets = try context.fetch(descriptor)
            var fixed = false
            for wallet in wallets {
                if wallet.balance < 0 {
                    print("🛠️ Fixing negative balance: \(wallet.name) was \(wallet.balance)")
                    wallet.balance = 0
                    fixed = true
                }
            }
            if fixed {
                try context.save()
                print("✅ Negative balances fixed and saved")
            }
        } catch {
            print("❌ Error fixing balances: \(error)")
        }
    }

    // MARK: - Save
    func save() {
        guard let context = modelContext else {
            print("❌ No model context available")
            return
        }
        do {
            try context.save()
            print("💾 Data saved successfully")
        } catch {
            print("❌ Error saving: \(error)")
        }
    }

    // MARK: - Fetch Users
    func fetchUsers() -> [User] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<User>()
        do {
            return try context.fetch(descriptor)
        } catch {
            print("❌ Error fetching users: \(error)")
            return []
        }
    }

    // MARK: - Fetch Wallets
    func fetchWallets() -> [Wallet] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<Wallet>(sortBy: [SortDescriptor(\.name)])
        do {
            let wallets = try context.fetch(descriptor)
            print("💰 fetchWallets: \(wallets.count) wallets found")
            for wallet in wallets {
                let displayBalance = max(wallet.balance, 0)
                print("   - \(wallet.name): \(displayBalance)")
            }
            return wallets
        } catch {
            print("❌ Error fetching wallets: \(error)")
            return []
        }
    }

    // MARK: - Fetch Categories
    func fetchCategories() -> [Category] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.name)])
        do {
            let categories = try context.fetch(descriptor)
            print("📋 Total categories in store: \(categories.count)")
            return categories
        } catch {
            print("❌ Error fetching categories: \(error)")
            return []
        }
    }

    func fetchCategories(type: TransactionType) -> [Category] {
        let allCategories = fetchCategories()
        return allCategories.filter { $0.type == type }
    }

    func fetchCategoriesWithSubcategories(type: TransactionType) -> [(parent: Category, subcategories: [Category])] {
        let allCategories = fetchCategories()
        let filtered = allCategories.filter { $0.type == type }

        // Separate parents and subcategories
        let parents = filtered.filter { $0.parentCategory == nil }
        let subcategories = filtered.filter { $0.parentCategory != nil }

        var result: [(parent: Category, subcategories: [Category])] = []
        for parent in parents {
            let subs = subcategories.filter { $0.parentCategory == parent.id.uuidString }
            result.append((parent: parent, subcategories: subs))
        }
        return result
    }

    // MARK: - Fetch Transactions
    func fetchTransactions() -> [Transaction] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<Transaction>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        do {
            return try context.fetch(descriptor)
        } catch {
            print("❌ Error fetching transactions: \(error)")
            return []
        }
    }

    // MARK: - Fetch Pockets
    func fetchPockets(for walletID: UUID) -> [Pocket] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<Pocket>(
            predicate: #Predicate { $0.walletID == walletID }
        )
        do {
            let pockets = try context.fetch(descriptor)
            print("📦 fetchPockets: \(pockets.count) pockets for wallet \(walletID)")
            return pockets
        } catch {
            print("❌ Error fetching pockets: \(error)")
            return []
        }
    }

    func fetchAllPockets() -> [Pocket] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<Pocket>()
        do {
            return try context.fetch(descriptor)
        } catch {
            print("❌ Error fetching all pockets: \(error)")
            return []
        }
    }

    // MARK: - Total Pocket Balance
    var totalPocketBalance: Double {
        let pockets = fetchAllPockets()
        return pockets.reduce(0) { $0 + $1.balance }
    }

    func totalPocketBalance(for walletID: UUID) -> Double {
        let pockets = fetchPockets(for: walletID)
        return pockets.reduce(0) { $0 + $1.balance }
    }

    // MARK: - Wallet Balance Update (SAFE)
    func updateWalletBalance(wallet: Wallet, amount: Double, isAddition: Bool) {
        let oldBalance = wallet.balance

        if isAddition {
            wallet.balance += amount
            print("   💰 Balance update: \(wallet.name) \(oldBalance) + \(amount) = \(wallet.balance)")
        } else {
            let newBalance = oldBalance - amount
            if newBalance < 0 {
                print("   ❌ BLOCKED: Insufficient balance in \(wallet.name): \(oldBalance) < \(amount)")
                wallet.balance = 0
            } else {
                wallet.balance = newBalance
                print("   💸 Balance update: \(wallet.name) \(oldBalance) - \(amount) = \(wallet.balance)")
            }
        }
    }

    // MARK: - Add Income
    func addIncome(amount: Double, note: String, date: Date, category: Category, wallet: Wallet, user: User) {
        guard let context = modelContext else { return }

        print("💰 ADD INCOME: +\(amount) to \(wallet.name) (current: \(wallet.balance))")

        let transaction = Transaction(
            amount: amount,
            note: note,
            date: date,
            type: .income,
            category: category,
            wallet: wallet,
            user: user
        )

        updateWalletBalance(wallet: wallet, amount: amount, isAddition: true)

        context.insert(transaction)
        save()

        print("✅ Income added: +\(amount) to \(wallet.name), balance: \(wallet.balance)")

        // Sync to Firebase
        syncTransactionToFirebase(transaction)
        syncWalletToFirebase(wallet)
    }

    // MARK: - Add Expense
    func addExpense(amount: Double, note: String, date: Date, category: Category, wallet: Wallet, user: User) {
        guard let context = modelContext else { return }

        print("💸 ADD EXPENSE: -\(amount) from \(wallet.name) (current: \(wallet.balance))")

        // Check balance
        if wallet.balance < amount {
            print("❌ BLOCKED: Insufficient balance in \(wallet.name): \(wallet.balance) < \(amount)")
            return
        }

        let transaction = Transaction(
            amount: amount,
            note: note,
            date: date,
            type: .expense,
            category: category,
            wallet: wallet,
            user: user
        )

        updateWalletBalance(wallet: wallet, amount: amount, isAddition: false)

        context.insert(transaction)
        save()

        print("✅ Expense added: -\(amount) from \(wallet.name), balance: \(wallet.balance)")

        syncTransactionToFirebase(transaction)
        syncWalletToFirebase(wallet)
    }

    // MARK: - Add Transfer
    func addTransfer(amount: Double, note: String, date: Date, fromWallet: Wallet, toWallet: Wallet, user: User) {
        guard let context = modelContext else { return }

        print("🔄 ADD TRANSFER: \(amount) from \(fromWallet.name)(\(fromWallet.balance)) → \(toWallet.name)(\(toWallet.balance))")

        // Check source balance
        if fromWallet.balance < amount {
            print("❌ BLOCKED: Insufficient balance in \(fromWallet.name): \(fromWallet.balance) < \(amount)")
            return
        }

        // Create transfer-out transaction
        let transferOut = Transaction(
            amount: amount,
            note: "Transfer ke \(toWallet.name): \(note)",
            date: date,
            type: .transfer,
            wallet: fromWallet,
            user: user,
            sourceWallet: fromWallet,
            destinationWallet: toWallet,
            isTransfer: true
        )

        // Create transfer-in transaction
        let transferIn = Transaction(
            amount: amount,
            note: "Transfer dari \(fromWallet.name): \(note)",
            date: date,
            type: .transfer,
            wallet: toWallet,
            user: user,
            sourceWallet: fromWallet,
            destinationWallet: toWallet,
            isTransfer: true
        )

        updateWalletBalance(wallet: fromWallet, amount: amount, isAddition: false)
        updateWalletBalance(wallet: toWallet, amount: amount, isAddition: true)

        context.insert(transferOut)
        context.insert(transferIn)
        save()

        print("✅ Transfer completed: \(amount) from \(fromWallet.name) to \(toWallet.name)")

        syncTransactionToFirebase(transferOut)
        syncTransactionToFirebase(transferIn)
        syncWalletToFirebase(fromWallet)
        syncWalletToFirebase(toWallet)
    }

    // MARK: - Delete Transaction
    func deleteTransaction(_ transaction: Transaction) {
        guard let context = modelContext else { return }

        print("🗑️ DELETE TRANSACTION: \(transaction.type.rawValue) \(transaction.amount)")

        // Reverse balance
        if let wallet = transaction.wallet {
            let oldBalance = wallet.balance
            if transaction.type == .income {
                wallet.balance -= transaction.amount
                print("   ↩️ Reverse income: \(wallet.name) \(oldBalance) - \(transaction.amount) = \(wallet.balance)")
            } else if transaction.type == .expense {
                wallet.balance += transaction.amount
                print("   ↩️ Reverse expense: \(wallet.name) \(oldBalance) + \(transaction.amount) = \(wallet.balance)")
            } else if transaction.type == .transfer {
                print("   ⚠️ Transfer delete - manual balance adjustment may be needed")
            }

            // Ensure non-negative
            if wallet.balance < 0 {
                print("   ⚠️ Balance went negative after delete, resetting to 0")
                wallet.balance = 0
            }

            syncWalletToFirebase(wallet)
        }

        context.delete(transaction)
        save()

        print("✅ Transaction deleted")
    }

    // MARK: - Setup Default Data
    func setupDefaultData() {
        guard let context = modelContext else { return }

        // Check if data already exists
        let userDescriptor = FetchDescriptor<User>()
        let categoryDescriptor = FetchDescriptor<Category>()
        let walletDescriptor = FetchDescriptor<Wallet>()

        do {
            let users = try context.fetch(userDescriptor)
            let categories = try context.fetch(categoryDescriptor)
            let wallets = try context.fetch(walletDescriptor)

            print("✅ Users already exist: \(users.count)")
            print("✅ Categories already exist: \(categories.count)")
            print("✅ Wallets already exist: \(wallets.count)")

            // Fix any negative balances
            fixNegativeBalances()

        } catch {
            print("❌ Error checking default data: \(error)")
        }
    }

    // MARK: - Firebase Sync
    private func syncTransactionToFirebase(_ transaction: Transaction) {
        guard let userId = transaction.user?.id else { return }
        let data: [String: Any] = [
            "amount": transaction.amount,
            "note": transaction.note,
            "date": Timestamp(date: transaction.date),
            "type": transaction.type.rawValue,
            "walletId": transaction.wallet?.id.uuidString ?? "",
            "categoryId": transaction.category?.id.uuidString ?? ""
        ]
        db.collection("users").document(userId.uuidString)
          .collection("transactions").document(transaction.id.uuidString)
          .setData(data) { error in
              if let error = error {
                  print("❌ Firebase sync error: \(error)")
              } else {
                  print("✅ Transaction synced to Firebase")
              }
          }
    }

    private func syncWalletToFirebase(_ wallet: Wallet) {
        guard let userId = wallet.user?.id else { return }
        let data: [String: Any] = [
            "name": wallet.name,
            "balance": wallet.balance,
            "type": wallet.type,
            "updatedAt": Timestamp(date: Date())
        ]
        db.collection("users").document(userId.uuidString)
          .collection("wallets").document(wallet.id.uuidString)
          .setData(data) { error in
              if let error = error {
                  print("❌ Wallet sync error: \(error)")
              }
          }
    }

    // MARK: - Transfer Between Pockets
    func transferBetweenPockets(from sourcePocket: Pocket, to destPocket: Pocket, amount: Double, note: String, date: Date) {
        guard let context = modelContext else { return }

        print("🔄 TRANSFER BETWEEN POCKETS: \(amount) from \(sourcePocket.name) to \(destPocket.name)")

        // Check source balance
        if sourcePocket.balance < amount {
            print("❌ BLOCKED: Insufficient balance in \(sourcePocket.name): \(sourcePocket.balance) < \(amount)")
            return
        }

        // Deduct from source
        sourcePocket.balance -= amount

        // Add to destination
        destPocket.balance += amount

        // Create transaction records
        let transferOut = PocketTransaction(
            amount: amount,
            note: "Transfer ke \(destPocket.name): \(note)",
            date: date,
            isDeposit: false,
            pocketID: sourcePocket.id,
            walletID: sourcePocket.walletID
        )

        let transferIn = PocketTransaction(
            amount: amount,
            note: "Transfer dari \(sourcePocket.name): \(note)",
            date: date,
            isDeposit: true,
            pocketID: destPocket.id,
            walletID: destPocket.walletID
        )

        context.insert(transferOut)
        context.insert(transferIn)
        save()

        print("✅ Pocket transfer completed: \(amount) from \(sourcePocket.name) to \(destPocket.name)")
    }

}
