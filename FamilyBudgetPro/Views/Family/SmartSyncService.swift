import Foundation
import SwiftData
import FirebaseFirestore
import FirebaseAuth
import Network
import Combine


// MARK: - Local Sync Queue Entry
@Model
class LocalSyncRecord {
    @Attribute(.unique) var id: UUID
    var entityType: String      // "Transaction", "Wallet", "Category", "Pocket"
    var entityId: UUID
    var action: String          // "created", "updated", "deleted"
    var jsonData: String        // Serialized entity data
    var familyCode: String?
    var firebaseUid: String
    var createdAt: Date
    var retryCount: Int
    var isSynced: Bool
    var lastError: String?

    init(entityType: String, entityId: UUID, action: String, jsonData: String,
         familyCode: String?, firebaseUid: String) {
        self.id = UUID()
        self.entityType = entityType
        self.entityId = entityId
        self.action = action
        self.jsonData = jsonData
        self.familyCode = familyCode
        self.firebaseUid = firebaseUid
        self.createdAt = Date()
        self.retryCount = 0
        self.isSynced = false
        self.lastError = nil
    }
}

// MARK: - Smart Sync Service

class SmartSyncService: ObservableObject {
    static let shared = SmartSyncService()

    @Published var isOnline: Bool = false
    @Published var isSyncing: Bool = false
    @Published var pendingCount: Int = 0
    @Published var lastSyncMessage: String = ""

    private let db = Firestore.firestore()
    private var networkMonitor: NWPathMonitor?
    private var syncTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        startNetworkMonitoring()
        startPeriodicSync()
    }

    // MARK: - Network Monitoring
    private func startNetworkMonitoring() {
        networkMonitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkMonitor")

        networkMonitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let wasOffline = !(self?.isOnline ?? false)
                self?.isOnline = path.status == .satisfied

                // Came back online → trigger sync
                if wasOffline && self?.isOnline == true {
                    self?.lastSyncMessage = "Koneksi kembali, menyinkronkan..."
                    Task {
                        await self?.syncPendingRecords()
                    }
                }
            }
        }
        networkMonitor?.start(queue: queue)
    }

    // MARK: - Periodic Sync (every 30 seconds when online)
    private func startPeriodicSync() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            guard self?.isOnline == true else { return }
            Task {
                await self?.syncPendingRecords()
            }
        }
    }

    // MARK: - Queue Operations

    /// Enqueue a record for sync (called from DataService when creating/updating/deleting)
    func enqueue<T: Encodable>(entity: T, entityType: String, action: String,
                                familyCode: String?, modelContext: ModelContext) {
        guard let firebaseUid = Auth.auth().currentUser?.uid else { return }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(entity),
              let jsonString = String(data: data, encoding: .utf8) else {
            print("❌ Failed to encode entity for sync queue")
            return
        }

        let record = LocalSyncRecord(
            entityType: entityType,
            entityId: UUID(),
            action: action,
            jsonData: jsonString,
            familyCode: familyCode,
            firebaseUid: firebaseUid
        )

        modelContext.insert(record)
        try? modelContext.save()

        updatePendingCount(modelContext: modelContext)

        // If online, try sync immediately
        if isOnline {
            Task {
                await syncPendingRecords(modelContext: modelContext)
            }
        }
    }

    /// Get pending records count
    func updatePendingCount(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<LocalSyncRecord>(
            predicate: #Predicate { $0.isSynced == false }
        )
        if let records = try? modelContext.fetch(descriptor) {
            pendingCount = records.count
        }
    }

    // MARK: - Sync Logic

    func syncPendingRecords(modelContext: ModelContext? = nil) async {
        guard isOnline, !isSyncing else { return }
        guard let user = Auth.auth().currentUser else {
            lastSyncMessage = "Belum login"
            return
        }

        isSyncing = true
        defer { isSyncing = false }

        // Use provided context or get from shared
        let context = modelContext ?? getModelContext()
        guard let ctx = context else {
            lastSyncMessage = "Context tidak tersedia"
            return
        }

        let descriptor = FetchDescriptor<LocalSyncRecord>(
            predicate: #Predicate { $0.isSynced == false && $0.retryCount < 5 }
        )

        guard let pendingRecords = try? ctx.fetch(descriptor), !pendingRecords.isEmpty else {
            lastSyncMessage = "Tidak ada data yang perlu disinkronkan"
            updatePendingCount(modelContext: ctx)
            return
        }

        lastSyncMessage = "Menyinkronkan \(pendingRecords.count) data..."

        for record in pendingRecords {
            do {
                try await syncSingleRecord(record, userId: user.uid, context: ctx)
            } catch {
                record.retryCount += 1
                record.lastError = error.localizedDescription
                if record.retryCount >= 5 {
                    record.isSynced = true // Mark as failed, don't retry forever
                }
            }
        }

        try? ctx.save()
        updatePendingCount(modelContext: ctx)
        lastSyncMessage = "Sinkronisasi selesai"
    }

    private func syncSingleRecord(_ record: LocalSyncRecord, userId: String, context: ModelContext) async throws {
        let collectionRef: CollectionReference

        if let familyCode = record.familyCode, !familyCode.isEmpty {
            collectionRef = db
                .collection("families")
                .document(familyCode)
                .collection(record.entityType.lowercased() + "s")
        } else {
            collectionRef = db.collection("users").document(userId).collection(record.entityType.lowercased() + "s")
        }

        let docRef = collectionRef.document(record.entityId.uuidString)

        // Parse JSON back to dictionary
        guard let jsonData = record.jsonData.data(using: .utf8),
              var data = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw NSError(domain: "SyncError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON data"])
        }

        // Add metadata
        data["syncedAt"] = Timestamp(date: Date())
        data["firebaseUid"] = record.firebaseUid
        data["familyCode"] = record.familyCode ?? ""

        if record.action == "deleted" {
            try await docRef.delete()
        } else {
            try await docRef.setData(data, merge: true)
        }

        // Mark as synced and delete from local queue (keep for 7 days then purge)
        record.isSynced = true

        // Delete immediately to keep local clean (data already in SwiftData main models)
        context.delete(record)
    }

    // MARK: - Pull from Cloud (when joining family, atau saat app launch untuk restore data setelah install ulang)
    func pullFamilyData(familyCode: String, modelContext: ModelContext) async throws {
        guard isOnline, Auth.auth().currentUser != nil else { return }

        let familyRef = db.collection("families").document(familyCode)
        try await restoreCollections(from: familyRef, modelContext: modelContext)

        lastSyncMessage = "Data keluarga berhasil diunduh"
    }

    /// Restore data personal (belum join keluarga) dari `users/{uid}/...` di Firestore.
    /// Dipanggil saat app launch untuk kasus user yang belum tergabung keluarga manapun.
    func pullPersonalData(firebaseUid: String, modelContext: ModelContext) async throws {
        guard isOnline else { return }

        let userRef = db.collection("users").document(firebaseUid)
        try await restoreCollections(from: userRef, modelContext: modelContext)

        lastSyncMessage = "Data berhasil diunduh"
    }

    /// Logika inti restore, dipakai baik untuk path `families/{code}` maupun `users/{uid}`.
    /// Urutan penting: Wallet & Category dulu (tidak ada dependency), baru Transaction & Pocket
    /// (butuh referensi Wallet/Category yang sudah di-restore).
    ///
    /// ⭐ FIX: sebelumnya semua `modelContext.insert()`/`.save()` dijalankan langsung setelah
    /// `await ref.collection(...).getDocuments()` — karena `await` bisa membuat eksekusi
    /// lanjut di thread lain (bukan MainActor tempat `mainContext` hidup), perubahan data
    /// TETAP tersimpan tapi Views yang pakai `@Query` (live/reactive ke SwiftData, mis. di
    /// DashboardView) tidak langsung ter-update — baru terlihat setelah View dibuat ulang
    /// (contoh: logout lalu login lagi). Sekarang semua panggilan jaringan (getDocuments)
    /// dikerjakan dulu, baru SEMUA mutasi SwiftData dibungkus `MainActor.run` supaya terjadi
    /// di actor/thread yang sama dengan `mainContext`, sehingga `@Query` langsung ter-update.
    private func restoreCollections(from ref: DocumentReference, modelContext: ModelContext) async throws {
        // 1. Ambil semua data dari Firestore dulu (network, boleh di thread manapun)
        let walletSnapshot = try await ref.collection("wallets").getDocuments()
        let categorySnapshot = try await ref.collection("categories").getDocuments()
        let pocketSnapshot = try await ref.collection("pockets").getDocuments()
        let transactionSnapshot = try await ref.collection("transactions").getDocuments()

        // 2. Semua mutasi SwiftData dijalankan di MainActor (thread yang sama dengan mainContext)
        try await MainActor.run {
            // Wallets
            let existingWallets = (try? modelContext.fetch(FetchDescriptor<Wallet>())) ?? []
            var walletsByID: [UUID: Wallet] = Dictionary(uniqueKeysWithValues: existingWallets.map { ($0.id, $0) })

            for doc in walletSnapshot.documents {
                guard let idString = doc.data()["id"] as? String, let id = UUID(uuidString: idString) else { continue }
                if walletsByID[id] != nil { continue } // sudah ada lokal, jangan timpa
                if let wallet = Wallet.fromFirestoreData(doc.data()) {
                    modelContext.insert(wallet)
                    walletsByID[id] = wallet
                }
            }

            // Categories (2-pass: buat dulu semua, baru sambungkan parent-child)
            let existingCategories = (try? modelContext.fetch(FetchDescriptor<Category>())) ?? []
            var categoriesByID: [UUID: Category] = Dictionary(uniqueKeysWithValues: existingCategories.map { ($0.id, $0) })
            var pendingParentLinks: [(child: Category, parentID: UUID)] = []

            for doc in categorySnapshot.documents {
                let data = doc.data()
                guard let idString = data["id"] as? String, let id = UUID(uuidString: idString) else { continue }
                if categoriesByID[id] != nil { continue }
                if let category = Category.fromFirestoreData(data) {
                    modelContext.insert(category)
                    categoriesByID[id] = category
                    if let parentIdString = data["parentId"] as? String, !parentIdString.isEmpty,
                       let parentID = UUID(uuidString: parentIdString) {
                        pendingParentLinks.append((category, parentID))
                    }
                }
            }
            for link in pendingParentLinks {
                link.child.parentCategory = categoriesByID[link.parentID]
            }

            // Pockets
            let existingPockets = (try? modelContext.fetch(FetchDescriptor<Pocket>())) ?? []
            var existingPocketIDs = Set(existingPockets.map { $0.id })

            for doc in pocketSnapshot.documents {
                guard let idString = doc.data()["id"] as? String, let id = UUID(uuidString: idString) else { continue }
                if existingPocketIDs.contains(id) { continue }
                if let pocket = Pocket.fromFirestoreData(doc.data()) {
                    modelContext.insert(pocket)
                    existingPocketIDs.insert(id)
                }
            }

            // Transactions (butuh wallet & category yang sudah di-restore di atas)
            let existingTransactions = (try? modelContext.fetch(FetchDescriptor<Transaction>())) ?? []
            var existingTransactionIDs = Set(existingTransactions.map { $0.id })

            for doc in transactionSnapshot.documents {
                guard let idString = doc.data()["id"] as? String, let id = UUID(uuidString: idString) else { continue }
                if existingTransactionIDs.contains(id) { continue }
                if let transaction = Transaction.fromFirestoreData(
                    doc.data(),
                    walletsByID: walletsByID,
                    categoriesByID: categoriesByID
                ) {
                    modelContext.insert(transaction)
                    existingTransactionIDs.insert(id)
                }
            }

            try modelContext.save()
            print("✅ Restore selesai: \(walletsByID.count) wallet, \(categoriesByID.count) kategori, \(existingPocketIDs.count) pocket, \(existingTransactionIDs.count) transaksi")
        }
    }

    // MARK: - Helper
    private func getModelContext() -> ModelContext? {
        // This should return the shared model context from your app
        // You'll need to set this up in your app initialization
        return nil
    }

    deinit {
        networkMonitor?.cancel()
        syncTimer?.invalidate()
    }
}
