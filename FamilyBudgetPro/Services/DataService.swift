import Foundation
import SwiftData
import Combine
import FirebaseAuth
import FirebaseFirestore



class DataService: ObservableObject {

    static let shared = DataService()

    var modelContext: ModelContext?
    var modelContainer: ModelContainer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Firebase (LAZY — ini yang fix crash!)
    private var _firestore: Firestore?
    private var _auth: Auth?

    private var firestore: Firestore {
        if let existing = _firestore { return existing }
        let db = Firestore.firestore()
        _firestore = db
        print("🔥 Firestore lazy-initialized")
        return db
    }

    private var auth: Auth {
        if let existing = _auth { return existing }
        let authInstance = Auth.auth()
        _auth = authInstance
        print("🔐 Auth lazy-initialized")
        return authInstance
    }

    private init() {
        print("🚀 DataService initialized (Firebase NOT yet touched)")
    }
    // ⭐ FAMILY SHARING HELPERS
    private func getCurrentFamilyCode() -> String? {
        guard let user = Auth.auth().currentUser else { return nil }
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profiles = try? modelContext?.fetch(descriptor),
              let profile = profiles.first(where: { $0.firebaseUid == user.uid }) else { return nil }
        return profile.familyCode
    }

    private func getCurrentUserId() -> String? {
        return Auth.auth().currentUser?.uid
    }

    // ⭐ SMART SYNC HELPER
    private func enqueueForSync<T: Encodable>(
        entity: T,
        entityType: String,
        action: String
    ) {
        guard let context = modelContext else { return }
        let familyCode = getCurrentFamilyCode()
        SmartSyncService.shared.enqueue(
            entity: entity,
            entityType: entityType,
            action: action,
            familyCode: familyCode,
            modelContext: context
        )
    }


    // MARK: - Setup Methods

    func setModelContainer(_ container: ModelContainer) {
        self.modelContainer = container
        self.modelContext = container.mainContext
        print("✅ DataService container set — using mainContext")
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

    // MARK: - Fetch UserProfiles
    func fetchUserProfiles() -> [UserProfile] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<UserProfile>()
        do {
            return try context.fetch(descriptor)
        } catch {
            print("❌ Error fetching user profiles: \(error)")
            return []
        }
    }

    // MARK: - Fetch Wallets
    func fetchWallets() -> [Wallet] {
        guard let context = modelContext else { return [] }
        let currentFamilyCode = getCurrentFamilyCode()
        let descriptor = FetchDescriptor<Wallet>(
            predicate: #Predicate<Wallet> { $0.familyCode == currentFamilyCode },
            sortBy: [SortDescriptor(\.name)]
        )
        do {
            let wallets = try context.fetch(descriptor)
            print("💰 fetchWallets: \(wallets.count) wallets found (family: \(currentFamilyCode ?? "nil"))")
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
        let currentFamilyCode = getCurrentFamilyCode()
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { $0.familyCode == currentFamilyCode },
            sortBy: [SortDescriptor(\.name)]
        )
        do {
            let categories = try context.fetch(descriptor)
            print("📋 Total categories in store (family: \(currentFamilyCode ?? "nil")): \(categories.count)")
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

        let parents = filtered.filter { $0.parentCategory == nil }
        let subcategories = filtered.filter { $0.parentCategory != nil }

        var result: [(parent: Category, subcategories: [Category])] = []
        for parent in parents {
            let subs = subcategories.filter { $0.parentCategory?.id == parent.id }
            result.append((parent: parent, subcategories: subs))
        }
        return result
    }

    // MARK: - Fetch Transactions
    func fetchTransactions() -> [Transaction] {
        guard let context = modelContext else { return [] }
        let currentFamilyCode = getCurrentFamilyCode()
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate<Transaction> { $0.familyCode == currentFamilyCode },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
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
        let targetWalletID = walletID
        let currentFamilyCode = getCurrentFamilyCode()
        let descriptor = FetchDescriptor<Pocket>(
            predicate: #Predicate<Pocket> { $0.walletID == targetWalletID && $0.familyCode == currentFamilyCode }
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
        let currentFamilyCode = getCurrentFamilyCode()
        let descriptor = FetchDescriptor<Pocket>(
            predicate: #Predicate<Pocket> { $0.familyCode == currentFamilyCode }
        )
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

        let familyCode = getCurrentFamilyCode()
        let firebaseUid = getCurrentUserId()

        let transaction = Transaction(
            amount: amount,
            note: note,
            date: date,
            type: .income,
            category: category,
            wallet: wallet,
            user: user,
            familyCode: familyCode,
            firebaseUid: firebaseUid
        )

        updateWalletBalance(wallet: wallet, amount: amount, isAddition: true)
        wallet.familyCode = familyCode
        wallet.firebaseUid = firebaseUid

        context.insert(transaction)
        save()

        print("✅ Income added: +\(amount) to \(wallet.name), balance: \(wallet.balance)")

        // ⭐ CREATE SYNC RECORD
        createSyncRecord(entityType: "Transaction", entityId: transaction.id, action: "created")
        createSyncRecord(entityType: "Wallet", entityId: wallet.id, action: "updated")

        // ⭐ SYNC TO FIREBASE
        syncTransactionToFirebase(transaction)
        syncWalletToFirebase(wallet)
    }

    // MARK: - Add Expense
    func addExpense(amount: Double, note: String, date: Date, category: Category, wallet: Wallet, user: User) {
        guard let context = modelContext else { return }

        print("💸 ADD EXPENSE: -\(amount) from \(wallet.name) (current: \(wallet.balance))")

        if wallet.balance < amount {
            print("❌ BLOCKED: Insufficient balance in \(wallet.name): \(wallet.balance) < \(amount)")
            return
        }

        let familyCode = getCurrentFamilyCode()
        let firebaseUid = getCurrentUserId()

        let transaction = Transaction(
            amount: amount,
            note: note,
            date: date,
            type: .expense,
            category: category,
            wallet: wallet,
            user: user,
            familyCode: familyCode,
            firebaseUid: firebaseUid
        )

        updateWalletBalance(wallet: wallet, amount: amount, isAddition: false)
        wallet.familyCode = familyCode
        wallet.firebaseUid = firebaseUid

        context.insert(transaction)
        save()

        print("✅ Expense added: -\(amount) from \(wallet.name), balance: \(wallet.balance)")

        // ⭐ CREATE SYNC RECORD
        createSyncRecord(entityType: "Transaction", entityId: transaction.id, action: "created")
        createSyncRecord(entityType: "Wallet", entityId: wallet.id, action: "updated")

        // ⭐ SYNC TO FIREBASE
        syncTransactionToFirebase(transaction)
        syncWalletToFirebase(wallet)
    }

    // MARK: - Add Transfer
    func addTransfer(amount: Double, note: String, date: Date, fromWallet: Wallet, toWallet: Wallet, user: User) {
        guard let context = modelContext else { return }

        print("🔄 ADD TRANSFER: \(amount) from \(fromWallet.name)(\(fromWallet.balance)) → \(toWallet.name)(\(toWallet.balance))")

        if fromWallet.balance < amount {
            print("❌ BLOCKED: Insufficient balance in \(fromWallet.name): \(fromWallet.balance) < \(amount)")
            return
        }

        let familyCode = getCurrentFamilyCode()
        let firebaseUid = getCurrentUserId()

        let transferOut = Transaction(
            amount: amount,
            note: "Transfer ke \(toWallet.name): \(note)",
            date: date,
            type: .transfer,
            wallet: fromWallet,
            user: user,
            sourceWallet: fromWallet,
            destinationWallet: toWallet,
            isTransfer: true,
            familyCode: familyCode,
            firebaseUid: firebaseUid
        )

        let transferIn = Transaction(
            amount: amount,
            note: "Transfer dari \(fromWallet.name): \(note)",
            date: date,
            type: .transfer,
            wallet: toWallet,
            user: user,
            sourceWallet: fromWallet,
            destinationWallet: toWallet,
            isTransfer: true,
            familyCode: familyCode,
            firebaseUid: firebaseUid
        )

        updateWalletBalance(wallet: fromWallet, amount: amount, isAddition: false)
        updateWalletBalance(wallet: toWallet, amount: amount, isAddition: true)
        fromWallet.familyCode = familyCode
        fromWallet.firebaseUid = firebaseUid
        toWallet.familyCode = familyCode
        toWallet.firebaseUid = firebaseUid

        context.insert(transferOut)
        context.insert(transferIn)
        save()

        print("✅ Transfer completed: \(amount) from \(fromWallet.name) to \(toWallet.name)")

        // ⭐ CREATE SYNC RECORD
        createSyncRecord(entityType: "Transaction", entityId: transferOut.id, action: "created")
        createSyncRecord(entityType: "Transaction", entityId: transferIn.id, action: "created")
        createSyncRecord(entityType: "Wallet", entityId: fromWallet.id, action: "updated")
        createSyncRecord(entityType: "Wallet", entityId: toWallet.id, action: "updated")

        // ⭐ SYNC TO FIREBASE
        syncTransactionToFirebase(transferOut)
        syncTransactionToFirebase(transferIn)
        syncWalletToFirebase(fromWallet)
        syncWalletToFirebase(toWallet)
    }

    // MARK: - Delete Transaction
    func deleteTransaction(_ transaction: Transaction) {
        guard let context = modelContext else { return }

        print("🗑️ DELETE TRANSACTION: \(transaction.type.rawValue) \(transaction.amount)")

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

            if wallet.balance < 0 {
                print("   ⚠️ Balance went negative after delete, resetting to 0")
                wallet.balance = 0
            }

            // ⭐ CREATE SYNC RECORD
            createSyncRecord(entityType: "Wallet", entityId: wallet.id, action: "updated")
            syncWalletToFirebase(wallet)
        }

        // ⭐ CREATE SYNC RECORD
        createSyncRecord(entityType: "Transaction", entityId: transaction.id, action: "deleted")

        context.delete(transaction)
        save()

        print("✅ Transaction deleted")
    }

    // MARK: - Setup Default Data
    func setupDefaultData() {
        guard let context = modelContext else { return }

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

            fixNegativeBalances()

        } catch {
            print("❌ Error checking default data: \(error)")
        }
    }

    // MARK: - Firebase Sync Helpers
    private func createSyncRecord(entityType: String, entityId: UUID, action: String) {
        guard let context = modelContext else { return }
        FirebaseSyncService.shared.createSyncRecord(
            entityType: entityType,
            entityId: entityId,
            action: action,
            modelContext: context
        )
    }

    private func syncTransactionToFirebase(_ transaction: Transaction) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let data: [String: Any] = [
            "amount": transaction.amount,
            "note": transaction.note,
            "date": Timestamp(date: transaction.date),
            "type": transaction.type.rawValue,
            "walletId": transaction.wallet?.id.uuidString ?? "",
            "categoryId": transaction.category?.id.uuidString ?? "",
            "isTransfer": transaction.isTransfer,
            "userId": userId,
            "updatedAt": Timestamp(date: Date())
        ]
        firestore.collection("users").document(userId)
            .collection("transactions").document(transaction.id.uuidString)
            .setData(data, merge: true) { error in
                if let error = error {
                    print("❌ Firebase sync error (transaction): \(error)")
                } else {
                    print("✅ Transaction synced to Firebase")
                }
            }
    }

    private func syncWalletToFirebase(_ wallet: Wallet) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let data: [String: Any] = [
            "name": wallet.name,
            "balance": wallet.balance,
            "type": wallet.type,
            "bankCode": wallet.bankCode ?? "",
            "accountNumber": wallet.accountNumber ?? "",
            "icon": wallet.icon,
            "color": wallet.color,
            "userId": userId,
            "updatedAt": Timestamp(date: Date())
        ]
        firestore.collection("users").document(userId)
            .collection("wallets").document(wallet.id.uuidString)
            .setData(data, merge: true) { error in
                if let error = error {
                    print("❌ Firebase sync error (wallet): \(error)")
                } else {
                    print("✅ Wallet synced to Firebase")
                }
            }
    }

    // MARK: - Transfer Between Pockets
    func transferBetweenPockets(from sourcePocket: Pocket, to destPocket: Pocket, amount: Double, note: String, date: Date) {
        guard let context = modelContext else { return }

        print("🔄 TRANSFER BETWEEN POCKETS: \(amount) from \(sourcePocket.name) to \(destPocket.name)")

        if sourcePocket.balance < amount {
            print("❌ BLOCKED: Insufficient balance in \(sourcePocket.name): \(sourcePocket.balance) < \(amount)")
            return
        }

        sourcePocket.balance -= amount
        destPocket.balance += amount

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

        // ⭐ CREATE SYNC RECORD
        createSyncRecord(entityType: "Pocket", entityId: sourcePocket.id, action: "updated")
        createSyncRecord(entityType: "Pocket", entityId: destPocket.id, action: "updated")

        print("✅ Pocket transfer completed: \(amount) from \(sourcePocket.name) to \(destPocket.name)")
    }

    // MARK: - Fetch Pocket Transactions
    func fetchPocketTransactions(for pocket: Pocket) -> [PocketTransaction] {
        guard let context = modelContext else { return [] }
        let pocketID = pocket.id
        let descriptor = FetchDescriptor<PocketTransaction>(
            predicate: #Predicate { $0.pocketID == pocketID },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        do {
            return try context.fetch(descriptor)
        } catch {
            print("❌ Error fetching pocket transactions: \(error)")
            return []
        }
    }

    // MARK: - Delete Pocket
    func deletePocket(_ pocket: Pocket) {
        guard let context = modelContext else { return }

        print("🗑️ DELETE POCKET: \(pocket.name)")

        if pocket.balance > 0, let walletID = pocket.walletID {
            let targetWalletID = walletID
            let walletDescriptor = FetchDescriptor<Wallet>(
                predicate: #Predicate { $0.id == targetWalletID }
            )
            if let wallet = try? context.fetch(walletDescriptor).first {
                wallet.balance += pocket.balance
                wallet.updatedAt = Date()
                print("   ↩️ Returned \(pocket.balance) to wallet \(wallet.name)")

                // ⭐ SYNC
                createSyncRecord(entityType: "Wallet", entityId: wallet.id, action: "updated")
                syncWalletToFirebase(wallet)
            }
        }

        let pocketID = pocket.id
        let transactionDescriptor = FetchDescriptor<PocketTransaction>(
            predicate: #Predicate { $0.pocketID == pocketID }
        )
        if let transactions = try? context.fetch(transactionDescriptor) {
            for transaction in transactions {
                context.delete(transaction)
            }
        }

        // ⭐ CREATE SYNC RECORD
        createSyncRecord(entityType: "Pocket", entityId: pocket.id, action: "deleted")

        context.delete(pocket)
        save()

        print("✅ Pocket deleted: \(pocket.name)")
    }

    // MARK: - Update Pocket
    func updatePocket(_ pocket: Pocket, name: String? = nil, targetAmount: Double? = nil, allocationPercentage: Double? = nil, icon: String? = nil, colorHex: String? = nil) {
        if let name = name {
            pocket.name = name
        }
        if let targetAmount = targetAmount {
            pocket.targetAmount = targetAmount
        }
        if let allocationPercentage = allocationPercentage {
            pocket.allocationPercentage = allocationPercentage
        }
        if let icon = icon {
            pocket.icon = icon
        }
        if let colorHex = colorHex {
            pocket.colorHex = colorHex
        }

        save()

        // ⭐ CREATE SYNC RECORD
        createSyncRecord(entityType: "Pocket", entityId: pocket.id, action: "updated")

        print("✅ Pocket updated: \(pocket.name)")
    }

    // MARK: - Deposit to Pocket
    func depositToPocket(pocket: Pocket, amount: Double, from wallet: Wallet, note: String, date: Date) {
        guard let context = modelContext else { return }

        print("📥 DEPOSIT TO POCKET: \(amount) from \(wallet.name) to \(pocket.name)")

        guard wallet.balance >= amount else {
            print("❌ BLOCKED: Insufficient balance in \(wallet.name): \(wallet.balance) < \(amount)")
            return
        }

        wallet.balance -= amount
        wallet.updatedAt = Date()

        pocket.balance += amount

        let pocketTransaction = PocketTransaction(
            amount: amount,
            note: note.isEmpty ? "Setor ke \(pocket.name)" : note,
            date: date,
            isDeposit: true,
            pocketID: pocket.id,
            walletID: wallet.id
        )

        context.insert(pocketTransaction)
        save()

        // ⭐ CREATE SYNC RECORD
        createSyncRecord(entityType: "Pocket", entityId: pocket.id, action: "updated")
        createSyncRecord(entityType: "Wallet", entityId: wallet.id, action: "updated")

        // ⭐ SYNC TO FIREBASE
        syncWalletToFirebase(wallet)

        print("✅ Deposit completed: \(amount) to \(pocket.name), wallet balance: \(wallet.balance)")
    }

    // MARK: - Withdraw from Pocket
    func withdrawFromPocket(pocket: Pocket, amount: Double, to wallet: Wallet, note: String, date: Date) {
        guard let context = modelContext else { return }

        print("📤 WITHDRAW FROM POCKET: \(amount) from \(pocket.name) to \(wallet.name)")

        guard pocket.balance >= amount else {
            print("❌ BLOCKED: Insufficient balance in \(pocket.name): \(pocket.balance) < \(amount)")
            return
        }

        pocket.balance -= amount

        wallet.balance += amount
        wallet.updatedAt = Date()

        let pocketTransaction = PocketTransaction(
            amount: amount,
            note: note.isEmpty ? "Tarik dari \(pocket.name)" : note,
            date: date,
            isDeposit: false,
            pocketID: pocket.id,
            walletID: wallet.id
        )

        context.insert(pocketTransaction)
        save()

        // ⭐ CREATE SYNC RECORD
        createSyncRecord(entityType: "Pocket", entityId: pocket.id, action: "updated")
        createSyncRecord(entityType: "Wallet", entityId: wallet.id, action: "updated")

        // ⭐ SYNC TO FIREBASE
        syncWalletToFirebase(wallet)

        print("✅ Withdraw completed: \(amount) from \(pocket.name), wallet balance: \(wallet.balance)")
    }

    // MARK: - Add Wallet
    func addWallet(name: String, type: WalletType, bankCode: String? = nil, accountNumber: String? = nil, balance: Double = 0, icon: String? = nil, colorHex: String = "4A90E2", accountHolder: String? = nil) -> Wallet {
        guard let context = modelContext else {
            fatalError("No model context")
        }

        let familyCode = getCurrentFamilyCode()
        let firebaseUid = getCurrentUserId()

        let wallet = Wallet(
            name: name,
            type: type,
            bankCode: bankCode,
            accountNumber: accountNumber,
            balance: balance,
            icon: icon,
            colorHex: colorHex,
            accountHolder: accountHolder,
            familyCode: familyCode,
            firebaseUid: firebaseUid
        )

        context.insert(wallet)
        save()

        // ⭐ CREATE SYNC RECORD
        createSyncRecord(entityType: "Wallet", entityId: wallet.id, action: "created")

        // ⭐ SYNC TO FIREBASE
        syncWalletToFirebase(wallet)

        print("✅ Wallet added: \(wallet.name)")
        return wallet
    }

    // MARK: - Update Wallet
    func updateWallet(_ wallet: Wallet, name: String? = nil, balance: Double? = nil, icon: String? = nil, colorHex: String? = nil, isArchived: Bool? = nil) {
        if let name = name {
            wallet.name = name
        }
        if let balance = balance {
            wallet.balance = max(balance, 0)
        }
        if let icon = icon {
            wallet.icon = icon
        }
        if let colorHex = colorHex {
            wallet.colorHex = colorHex
        }
        if let isArchived = isArchived {
            wallet.isArchived = isArchived
        }
        wallet.updatedAt = Date()

        save()

        // ⭐ CREATE SYNC RECORD
        createSyncRecord(entityType: "Wallet", entityId: wallet.id, action: "updated")

        // ⭐ SYNC TO FIREBASE
        syncWalletToFirebase(wallet)

        print("✅ Wallet updated: \(wallet.name)")
    }

    // MARK: - Delete Wallet
    func deleteWallet(_ wallet: Wallet) {
        guard let context = modelContext else { return }

        print("🗑️ DELETE WALLET: \(wallet.name)")

        // Delete related transactions
        let walletId = wallet.id
        let transactionDescriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.wallet?.id == walletId }
        )
        if let transactions = try? context.fetch(transactionDescriptor) {
            for transaction in transactions {
                createSyncRecord(entityType: "Transaction", entityId: transaction.id, action: "deleted")
                context.delete(transaction)
            }
        }

        // ⭐ CREATE SYNC RECORD
        createSyncRecord(entityType: "Wallet", entityId: wallet.id, action: "deleted")

        context.delete(wallet)
        save()

        print("✅ Wallet deleted: \(wallet.name)")
    }

    // MARK: - Add Category
    func addCategory(name: String, type: TransactionType, icon: String, colorHex: String, parentCategory: Category? = nil, isDefault: Bool = false, isSystem: Bool = false, sortOrder: Int = 0) -> Category {
        guard let context = modelContext else {
            fatalError("No model context")
        }

        let familyCode = getCurrentFamilyCode()
        let firebaseUid = getCurrentUserId()

        let category = Category(
            name: name,
            type: type,
            icon: icon,
            colorHex: colorHex,
            parentCategory: parentCategory,
            isDefault: isDefault,
            isSystem: isSystem,
            sortOrder: sortOrder,
            familyCode: familyCode,
            firebaseUid: firebaseUid
        )

        context.insert(category)
        save()

        // ⭐ CREATE SYNC RECORD
        createSyncRecord(entityType: "Category", entityId: category.id, action: "created")

        print("✅ Category added: \(category.name)")
        return category
    }

    // MARK: - Update Category
    func updateCategory(_ category: Category, name: String? = nil, icon: String? = nil, colorHex: String? = nil) {
        if let name = name {
            category.name = name
        }
        if let icon = icon {
            category.icon = icon
        }
        if let colorHex = colorHex {
            category.colorHex = colorHex
        }

        save()

        // ⭐ CREATE SYNC RECORD
        createSyncRecord(entityType: "Category", entityId: category.id, action: "updated")

        print("✅ Category updated: \(category.name)")
    }

    // MARK: - Delete Category
    func deleteCategory(_ category: Category) {
        guard let context = modelContext else { return }

        if category.isSystem {
            print("❌ Cannot delete system category: \(category.name)")
            return
        }

        print("🗑️ DELETE CATEGORY: \(category.name)")

        // ⭐ CREATE SYNC RECORD
        createSyncRecord(entityType: "Category", entityId: category.id, action: "deleted")

        context.delete(category)
        save()

        print("✅ Category deleted: \(category.name)")
    }

    // MARK: - Seed Default Categories
    func seedDefaultCategories() {
        guard let context = modelContext else { return }

        let familyCode = getCurrentFamilyCode()
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { $0.familyCode == familyCode }
        )
        let existingCount = (try? context.fetch(descriptor).count) ?? 0

        guard existingCount == 0 else {
            print("✅ Categories already seeded for family \(familyCode ?? "nil"): \(existingCount)")
            return
        }

        print("🌱 Seeding default categories...")

        let firebaseUid = getCurrentUserId()

        // Seed income categories
        for item in Category.defaultIncomeCategories {

            let category = Category(
                name: item.name,
                type: .income,
                icon: item.icon,
                colorHex: item.color,
                isDefault: true,
                isSystem: item.isSystem,
                familyCode: familyCode,
                firebaseUid: firebaseUid
            )
            context.insert(category)
            createSyncRecord(entityType: "Category", entityId: category.id, action: "created")
        }

        // Seed expense parent categories
        var parentCategories: [String: Category] = [:]
        for item in Category.defaultExpenseParents {
            let category = Category(
                name: item.name,
                type: .expense,
                icon: item.icon,
                colorHex: item.color,
                isDefault: true,
                isSystem: true,
                sortOrder: item.sortOrder,
                familyCode: familyCode,
                firebaseUid: firebaseUid
            )
            context.insert(category)
            parentCategories[item.name] = category
            createSyncRecord(entityType: "Category", entityId: category.id, action: "created")
        }

        // Seed expense subcategories
        for item in Category.defaultExpenseSubcategories {
            if let parent = parentCategories[item.parentName] {
                let subcategory = Category(
                    name: item.name,
                    type: .expense,
                    icon: item.icon,
                    colorHex: item.color,
                    parentCategory: parent,
                    isDefault: true,
                    isSystem: false,
                    sortOrder: item.sortOrder,
                    familyCode: familyCode,
                    firebaseUid: firebaseUid
                )
                context.insert(subcategory)
                createSyncRecord(entityType: "Category", entityId: subcategory.id, action: "created")
            }
        }

        save()
        print("✅ Default categories seeded successfully")
    }
}
