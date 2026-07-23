import Foundation
import FirebaseFirestore
import FirebaseAuth
import SwiftData
import Combine

class FirebaseSyncService: ObservableObject {
    static let shared = FirebaseSyncService()

    private let db = Firestore.firestore()
    private var isSyncing = false
    private var syncTimer: Timer?

    private init() {}

    // MARK: - Auto Sync
    func startAutoSync(modelContext: ModelContext) {
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task {
                await self.syncAll(modelContext: modelContext)
            }
        }
        // Initial sync
        Task {
            await self.syncAll(modelContext: modelContext)
        }
    }

    func stopAutoSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }

    // MARK: - Sync All (FILTERED by firebaseUid)
    func syncAll(modelContext: ModelContext) async {
        guard !isSyncing else { return }
        guard let firebaseUser = Auth.auth().currentUser else { return }

        isSyncing = true
        defer { isSyncing = false }

        let familyCode = getCurrentFamilyCode(modelContext: modelContext)
        let firebaseUserId = firebaseUser.uid

        do {
            // 1. Sync pending records (deletions) - FILTERED by firebaseUid
            let syncDescriptor = FetchDescriptor<SyncRecord>(
                predicate: #Predicate { $0.syncedToFirebase == false && $0.firebaseUserId == firebaseUserId }
            )
            let pendingRecords = try modelContext.fetch(syncDescriptor)

            for record in pendingRecords {
                await syncRecord(record, firebaseUserId: firebaseUserId, familyCode: familyCode, modelContext: modelContext)
            }

            // 2. Sync Transactions - FILTERED by firebaseUid
            await syncTransactions(firebaseUserId: firebaseUserId, familyCode: familyCode, modelContext: modelContext)

            // 3. Sync Wallets - FILTERED by firebaseUid
            await syncWallets(firebaseUserId: firebaseUserId, familyCode: familyCode, modelContext: modelContext)

            // 4. Sync Categories - FILTERED by firebaseUid
            await syncCategories(firebaseUserId: firebaseUserId, familyCode: familyCode, modelContext: modelContext)

            // 5. Sync Pockets - FILTERED by firebaseUid
            await syncPockets(firebaseUserId: firebaseUserId, familyCode: familyCode, modelContext: modelContext)

            // 6. Sync UserProfiles
            await syncUserProfiles(firebaseUserId: firebaseUserId, modelContext: modelContext)

            // Update last sync
            let allProfiles = try modelContext.fetch(FetchDescriptor<UserProfile>())
            if let profile = allProfiles.first(where: { $0.firebaseUid == firebaseUserId }) {
                profile.lastSyncAt = Date()
                try? modelContext.save()
            }

            print("✅ Firebase sync completed at \(Date())")

        } catch {
            print("❌ Sync error: \(error)")
        }
    }

    // MARK: - Sync Transactions (FILTERED by firebaseUid)
    private func syncTransactions(firebaseUserId: String, familyCode: String?, modelContext: ModelContext) async {
        let descriptor: FetchDescriptor<Transaction>
        if let code = familyCode {
            descriptor = FetchDescriptor<Transaction>(
                predicate: #Predicate { $0.familyCode == code }
            )
        } else {
            descriptor = FetchDescriptor<Transaction>(
                predicate: #Predicate { $0.firebaseUid == firebaseUserId }
            )
        }

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
            print("✅ Synced \(transactions.count) transactions")
        } catch {
            print("❌ Transaction sync error: \(error)")
        }
    }

    // MARK: - Sync Wallets (FILTERED by firebaseUid)
    private func syncWallets(firebaseUserId: String, familyCode: String?, modelContext: ModelContext) async {
        let descriptor: FetchDescriptor<Wallet>
        if let code = familyCode {
            descriptor = FetchDescriptor<Wallet>(
                predicate: #Predicate { $0.familyCode == code }
            )
        } else {
            descriptor = FetchDescriptor<Wallet>(
                predicate: #Predicate { $0.firebaseUid == firebaseUserId }
            )
        }

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
            print("✅ Synced \(wallets.count) wallets")
        } catch {
            print("❌ Wallet sync error: \(error)")
        }
    }

    // MARK: - Sync Categories (FILTERED by firebaseUid)
    private func syncCategories(firebaseUserId: String, familyCode: String?, modelContext: ModelContext) async {
        let descriptor: FetchDescriptor<Category>
        if let code = familyCode {
            descriptor = FetchDescriptor<Category>(
                predicate: #Predicate { $0.familyCode == code }
            )
        } else {
            descriptor = FetchDescriptor<Category>(
                predicate: #Predicate { $0.firebaseUid == firebaseUserId }
            )
        }

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
            print("✅ Synced \(categories.count) categories")
        } catch {
            print("❌ Category sync error: \(error)")
        }
    }

    // MARK: - Sync Pockets (FILTERED by firebaseUid)
    private func syncPockets(firebaseUserId: String, familyCode: String?, modelContext: ModelContext) async {
        let descriptor: FetchDescriptor<Pocket>
        if let code = familyCode {
            descriptor = FetchDescriptor<Pocket>(
                predicate: #Predicate { $0.familyCode == code }
            )
        } else {
            descriptor = FetchDescriptor<Pocket>(
                predicate: #Predicate { $0.firebaseUid == firebaseUserId }
            )
        }

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
            print("✅ Synced \(pockets.count) pockets")
        } catch {
            print("❌ Pocket sync error: \(error)")
        }
    }

    // MARK: - Sync UserProfiles
    private func syncUserProfiles(firebaseUserId: String, modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { $0.firebaseUid == firebaseUserId }
        )
        guard let profiles = try? modelContext.fetch(descriptor) else { return }

        for profile in profiles {
            let docRef = db.collection("users").document(firebaseUserId)
            do {
                try await docRef.setData(profile.toFirestoreData(), merge: true)
            } catch {
                print("❌ UserProfile sync error: \(error)")
            }
        }
    }

    // MARK: - Sync Single Record
    private func syncRecord(_ record: SyncRecord, firebaseUserId: String, familyCode: String?, modelContext: ModelContext) async {
        record.syncedToFirebase = true
        try? modelContext.save()
    }

    // MARK: - Helpers
    private func getCurrentFamilyCode(modelContext: ModelContext) -> String? {
        guard let user = Auth.auth().currentUser else { return nil }
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profiles = try? modelContext.fetch(descriptor),
              let profile = profiles.first(where: { $0.firebaseUid == user.uid }) else { return nil }
        return profile.familyCode
    }
}
