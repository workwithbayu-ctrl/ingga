import Foundation
import FirebaseFirestore
import FirebaseAuth
import SwiftData

@Observable
class FirebaseSyncService {
    static let shared = FirebaseSyncService()

    private let db = Firestore.firestore()
    private var syncTimer: Timer?
    private var isSyncing = false

    private init() {}

    // MARK: - ⭐ FAMILY SHARING HELPER
    private func getCurrentFamilyCode(modelContext: ModelContext) -> String? {
        guard let user = Auth.auth().currentUser else { return nil }
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profiles = try? modelContext.fetch(descriptor),
              let profile = profiles.first(where: { $0.firebaseUid == user.uid }),
              let familyCode = profile.familyCode else { return nil }
        return familyCode
    }

    // MARK: - Start Auto Sync
    func startAutoSync(modelContext: ModelContext) {
        // Sync setiap 30 detik dan saat app masuk foreground
        syncTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            Task {
                await self.syncAll(modelContext: modelContext)
            }
        }

        // Sync pertama kali
        Task {
            await syncAll(modelContext: modelContext)
        }
    }

    func stopAutoSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }

    // MARK: - Sync All Pending Data
    func syncAll(modelContext: ModelContext) async {
        guard !isSyncing else { return }
        guard let firebaseUser = Auth.auth().currentUser else { return }

        isSyncing = true
        defer { isSyncing = false }

        let familyCode = getCurrentFamilyCode(modelContext: modelContext)

        do {
            // 1. Sync pending records (deletions)
            let syncDescriptor = FetchDescriptor<SyncRecord>(
                predicate: #Predicate { $0.syncedToFirebase == false }
            )
            let pendingRecords = try modelContext.fetch(syncDescriptor)

            for record in pendingRecords {
                await syncRecord(record, firebaseUserId: firebaseUser.uid, familyCode: familyCode, modelContext: modelContext)
            }

            // 2. Sync Transactions
            await syncTransactions(firebaseUserId: firebaseUser.uid, familyCode: familyCode, modelContext: modelContext)

            // 3. Sync Wallets
            await syncWallets(firebaseUserId: firebaseUser.uid, familyCode: familyCode, modelContext: modelContext)

            // 4. Sync Categories
            await syncCategories(firebaseUserId: firebaseUser.uid, familyCode: familyCode, modelContext: modelContext)

            // 5. Sync Pockets
            await syncPockets(firebaseUserId: firebaseUser.uid, familyCode: familyCode, modelContext: modelContext)

            // 6. Sync UserProfiles
            await syncUserProfiles(firebaseUserId: firebaseUser.uid, modelContext: modelContext)

            // Update last sync
            // FIX: Fetch all profiles and filter manually instead of using predicate
            let allProfiles = try modelContext.fetch(FetchDescriptor<UserProfile>())
            if let profile = allProfiles.first(where: { $0.firebaseUid == firebaseUser.uid }) {
                profile.lastSyncAt = Date()
                try? modelContext.save()
            }

            print("Firebase sync completed at \(Date())")

        } catch {
            print("Sync error: \(error.localizedDescription)")
        }
    }

    // MARK: - Individual Sync Methods

    private func syncRecord(_ record: SyncRecord, firebaseUserId: String, familyCode: String?, modelContext: ModelContext) async {
        do {
            let collectionRef: CollectionReference
            if let code = familyCode {
                collectionRef = db.collection("families").document(code).collection(record.entityType.lowercased() + "s")
            } else {
                collectionRef = db.collection("users").document(firebaseUserId).collection(record.entityType.lowercased() + "s")
            }
            let docRef = collectionRef.document(record.entityId.uuidString)

            switch record.action {
            case "deleted":
                try await docRef.delete()
            default:
                break
            }

            record.syncedToFirebase = true
            try? modelContext.save()

        } catch {
            print("Failed to sync record: \(error)")
        }
    }

    private func syncTransactions(firebaseUserId: String, familyCode: String?, modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Transaction>()
        guard let transactions = try? modelContext.fetch(descriptor) else { return }

        let batch = db.batch()
        let collectionRef: CollectionReference
        if let code = familyCode {
            collectionRef = db.collection("families").document(code).collection("transactions")
        } else {
            collectionRef = db.collection("users").document(firebaseUserId).collection("transactions")
        }

        for transaction in transactions {
            let docRef = collectionRef.document(transaction.id.uuidString)
            var data = transaction.toFirestoreData()
            data["familyCode"] = familyCode as Any
            data["firebaseUid"] = transaction.firebaseUid ?? firebaseUserId
            batch.setData(data, forDocument: docRef, merge: true)
        }

        do {
            try await batch.commit()
            print("Synced \(transactions.count) transactions")
        } catch {
            print("Transaction sync error: \(error)")
        }
    }

    private func syncWallets(firebaseUserId: String, familyCode: String?, modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Wallet>()
        guard let wallets = try? modelContext.fetch(descriptor) else { return }

        let batch = db.batch()
        let collectionRef: CollectionReference
        if let code = familyCode {
            collectionRef = db.collection("families").document(code).collection("wallets")
        } else {
            collectionRef = db.collection("users").document(firebaseUserId).collection("wallets")
        }

        for wallet in wallets {
            let docRef = collectionRef.document(wallet.id.uuidString)
            var data = wallet.toFirestoreData()
            data["familyCode"] = familyCode as Any
            data["firebaseUid"] = wallet.firebaseUid ?? firebaseUserId
            batch.setData(data, forDocument: docRef, merge: true)
        }

        do {
            try await batch.commit()
            print("Synced \(wallets.count) wallets")
        } catch {
            print("Wallet sync error: \(error)")
        }
    }

    private func syncCategories(firebaseUserId: String, familyCode: String?, modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Category>()
        guard let categories = try? modelContext.fetch(descriptor) else { return }

        let batch = db.batch()
        let collectionRef: CollectionReference
        if let code = familyCode {
            collectionRef = db.collection("families").document(code).collection("categories")
        } else {
            collectionRef = db.collection("users").document(firebaseUserId).collection("categories")
        }

        for category in categories {
            let docRef = collectionRef.document(category.id.uuidString)
            var data = category.toFirestoreData()
            data["familyCode"] = familyCode as Any
            data["firebaseUid"] = category.firebaseUid ?? firebaseUserId
            batch.setData(data, forDocument: docRef, merge: true)
        }

        do {
            try await batch.commit()
            print("Synced \(categories.count) categories")
        } catch {
            print("Category sync error: \(error)")
        }
    }

    private func syncPockets(firebaseUserId: String, familyCode: String?, modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Pocket>()
        guard let pockets = try? modelContext.fetch(descriptor) else { return }

        let batch = db.batch()
        let collectionRef: CollectionReference
        if let code = familyCode {
            collectionRef = db.collection("families").document(code).collection("pockets")
        } else {
            collectionRef = db.collection("users").document(firebaseUserId).collection("pockets")
        }

        for pocket in pockets {
            let docRef = collectionRef.document(pocket.id.uuidString)
            var data = pocket.toFirestoreData()
            data["familyCode"] = familyCode as Any
            data["firebaseUid"] = pocket.firebaseUid ?? firebaseUserId
            batch.setData(data, forDocument: docRef, merge: true)
        }

        do {
            try await batch.commit()
            print("Synced \(pockets.count) pockets")
        } catch {
            print("Pocket sync error: \(error)")
        }
    }

    private func syncUserProfiles(firebaseUserId: String, modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profiles = try? modelContext.fetch(descriptor) else { return }

        let batch = db.batch()
        let collectionRef = db.collection("users").document(firebaseUserId).collection("userProfiles")

        for profile in profiles {
            let docRef = collectionRef.document(profile.id.uuidString)
            let data = profile.toFirestoreData()
            batch.setData(data, forDocument: docRef, merge: true)
        }

        do {
            try await batch.commit()
            print("Synced \(profiles.count) user profiles")
        } catch {
            print("UserProfile sync error: \(error)")
        }
    }

    // MARK: - Create Sync Record
    func createSyncRecord(entityType: String, entityId: UUID, action: String, modelContext: ModelContext) {
        let record = SyncRecord(
            entityType: entityType,
            entityId: entityId,
            action: action,
            firebaseUserId: Auth.auth().currentUser?.uid
        )
        modelContext.insert(record)
        try? modelContext.save()
    }

    // MARK: - ⭐ FETCH FAMILY DATA (for new member joining)
    func fetchFamilyData(familyCode: String, modelContext: ModelContext) async {
        do {
            // Fetch transactions
            let transactionsSnapshot = try await db.collection("families")
                .document(familyCode).collection("transactions").getDocuments()
            for doc in transactionsSnapshot.documents {
                print("Fetched transaction: \(doc.documentID)")
            }

            // Fetch wallets
            let walletsSnapshot = try await db.collection("families")
                .document(familyCode).collection("wallets").getDocuments()
            for doc in walletsSnapshot.documents {
                print("Fetched wallet: \(doc.documentID)")
            }

            // Fetch categories
            let categoriesSnapshot = try await db.collection("families")
                .document(familyCode).collection("categories").getDocuments()
            for doc in categoriesSnapshot.documents {
                print("Fetched category: \(doc.documentID)")
            }

            // Fetch pockets
            let pocketsSnapshot = try await db.collection("families")
                .document(familyCode).collection("pockets").getDocuments()
            for doc in pocketsSnapshot.documents {
                print("Fetched pocket: \(doc.documentID)")
            }

        } catch {
            print("❌ Fetch family data error: \(error)")
        }
    }
}
