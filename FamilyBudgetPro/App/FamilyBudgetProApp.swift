import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import FirebaseFirestore

@main
struct FamilyBudgetProApp: App {

    @State private var isLoggedIn: Bool = false
    @State private var showSplash: Bool = true
    @StateObject private var authService = AuthService.shared

    let container: ModelContainer

    init() {
        FirebaseApp.configure()
        print("🔥 Firebase configured")

        let schema = Schema([
            User.self,
            Category.self,
            Wallet.self,
            Transaction.self,
            Pocket.self,
            PocketTransaction.self,
            UserProfile.self,
            SyncRecord.self,
            FamilyGroup.self,
            LocalSyncRecord.self
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            container = try ModelContainer(
                for: schema,
                configurations: [config]
            )
            print("✅ ModelContainer created (persistent)")
        } catch {
            fatalError(
                "Failed to create ModelContainer: \(error)"
            )
        }

        DataService.shared.setModelContainer(container)
        print("✅ DataService initialized")
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    LuxurySplashScreen()
                        .onAppear {
                            print("🎬 Splash screen appeared")
                            DispatchQueue.main.asyncAfter(
                                deadline: .now() + 5.5
                            ) {
                                withAnimation(
                                    .easeInOut(duration: 0.8)
                                ) {
                                    showSplash = false
                                    print(
                                        "🎬 Splash dismissed,"
                                        + " isLoggedIn: \(isLoggedIn)"
                                    )
                                }
                            }
                        }
                } else if isLoggedIn {
                    ContentView(onLogout: {
                        print("🚪 Logout CALLED! (switching root to LoginView)")
                        withAnimation(.easeInOut(duration: 0.5)) {
                            isLoggedIn = false
                            UserDefaults.standard.set(
                                false,
                                forKey: "isUserLoggedIn"
                            )
                            UserDefaults.standard.synchronize()
                            print("✅ Logged out")
                        }
                    })
                    .environmentObject(DataService.shared)
                    .onAppear {
                        print("🏠 ContentView appeared (logged in)")
                        Task {
                            // ⭐ FIX: Clear other users' data + stamp orphan before restore
                            await prepareDataForCurrentUser()

                            // ⭐ Restore data dari Firestore
                            await restoreCloudDataIfNeeded()
                            DataService.shared.setupDefaultData()
                            FirebaseSyncService.shared.startAutoSync(
                                modelContext: container.mainContext
                            )
                        }
                    }
                    .onDisappear {
                        FirebaseSyncService.shared.stopAutoSync()
                    }
                } else {
                    LoginView(
                        onLoginSuccess: {
                            print("🚀 onLoginSuccess CALLED!")
                            withAnimation(.easeInOut(duration: 0.5)) {
                                isLoggedIn = true
                                UserDefaults.standard.set(
                                    true,
                                    forKey: "isUserLoggedIn"
                                )
                                UserDefaults.standard.synchronize()
                                print("✅ isLoggedIn = TRUE")
                            }
                        }
                    )
                    .environmentObject(DataService.shared)
                    .onAppear {
                        print("🔐 LoginView appeared")
                    }
                }
            }
            .onAppear {
                let wasLoggedIn = UserDefaults.standard.bool(
                    forKey: "isUserLoggedIn"
                )
                let rememberMe = UserDefaults.standard.bool(
                    forKey: "rememberMe"
                )
                print(
                    "🔍 wasLoggedIn: \(wasLoggedIn),"
                    + " rememberMe: \(rememberMe)"
                )

                if wasLoggedIn && rememberMe {
                    print("🔍 Auto-login: rememberMe ON")
                    isLoggedIn = true
                } else if wasLoggedIn && !rememberMe {
                    print("🔍 Auto-login skipped: rememberMe OFF")
                    UserDefaults.standard.set(
                        false,
                        forKey: "isUserLoggedIn"
                    )
                    UserDefaults.standard.synchronize()
                }
            }
            // ⭐ Sumber kebenaran tunggal untuk logout
            .onChange(of: authService.isAuthenticated) { _, newValue in
                if !newValue && isLoggedIn {
                    print("🚪 authService.isAuthenticated == false -> switch to LoginView")
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isLoggedIn = false
                        UserDefaults.standard.set(false, forKey: "isUserLoggedIn")
                        UserDefaults.standard.synchronize()
                    }
                }
            }
        }
        .modelContainer(container)
    }

    // MARK: - Prepare data for current user (CLEAR other users' data + stamp orphan)
    private func prepareDataForCurrentUser() async {
        guard let firebaseUser = Auth.auth().currentUser else { return }
        let context = container.mainContext
        let currentUid = firebaseUser.uid

        print("🔍 Preparing data for user: \(currentUid)")

        // ⭐ STEP 1: Hapus data milik user lain
        await clearOtherUsersData(currentUid: currentUid, context: context)

        // ⭐ STEP 2: Stamp data orphan (firebaseUid nil) dengan uid user saat ini
        stampOrphanDataWithCurrentUser(uid: currentUid, context: context)
    }

    // MARK: - Clear data from other users (prevent cross-account data leak)
    private func clearOtherUsersData(currentUid: String, context: ModelContext) async {
        print("🧹 Clearing data from other users...")

        // Clear Wallets
        let walletDescriptor = FetchDescriptor<Wallet>()
        if let wallets = try? context.fetch(walletDescriptor) {
            var deletedCount = 0
            for wallet in wallets {
                if let uid = wallet.firebaseUid, uid != currentUid {
                    context.delete(wallet)
                    deletedCount += 1
                }
            }
            if deletedCount > 0 { print("   🗑️ Deleted \(deletedCount) wallet(s) from other user") }
        }

        // Clear Transactions
        let transactionDescriptor = FetchDescriptor<Transaction>()
        if let transactions = try? context.fetch(transactionDescriptor) {
            var deletedCount = 0
            for transaction in transactions {
                if let uid = transaction.firebaseUid, uid != currentUid {
                    context.delete(transaction)
                    deletedCount += 1
                }
            }
            if deletedCount > 0 { print("   🗑️ Deleted \(deletedCount) transaction(s) from other user") }
        }

        // Clear Categories
        let categoryDescriptor = FetchDescriptor<Category>()
        if let categories = try? context.fetch(categoryDescriptor) {
            var deletedCount = 0
            for category in categories {
                if let uid = category.firebaseUid, uid != currentUid {
                    context.delete(category)
                    deletedCount += 1
                }
            }
            if deletedCount > 0 { print("   🗑️ Deleted \(deletedCount) category(ies) from other user") }
        }

        // Clear Pockets
        let pocketDescriptor = FetchDescriptor<Pocket>()
        if let pockets = try? context.fetch(pocketDescriptor) {
            var deletedCount = 0
            for pocket in pockets {
                if let uid = pocket.firebaseUid, uid != currentUid {
                    context.delete(pocket)
                    deletedCount += 1
                }
            }
            if deletedCount > 0 { print("   🗑️ Deleted \(deletedCount) pocket(s) from other user") }
        }

        try? context.save()
        print("✅ Other users' data cleared")
    }

    // MARK: - Stamp orphan data (created before firebaseUid field existed)
    private func stampOrphanDataWithCurrentUser(uid: String, context: ModelContext) {
        print("🏷️ Stamping orphan data with uid: \(uid)")

        // Stamp Wallets
        if let wallets = try? context.fetch(FetchDescriptor<Wallet>()) {
            for wallet in wallets where wallet.firebaseUid == nil {
                wallet.firebaseUid = uid
            }
        }

        // Stamp Transactions
        if let transactions = try? context.fetch(FetchDescriptor<Transaction>()) {
            for transaction in transactions where transaction.firebaseUid == nil {
                transaction.firebaseUid = uid
            }
        }

        // Stamp Categories
        if let categories = try? context.fetch(FetchDescriptor<Category>()) {
            for category in categories where category.firebaseUid == nil {
                category.firebaseUid = uid
            }
        }

        // Stamp Pockets
        if let pockets = try? context.fetch(FetchDescriptor<Pocket>()) {
            for pocket in pockets where pocket.firebaseUid == nil {
                pocket.firebaseUid = uid
            }
        }

        try? context.save()
        print("✅ Orphan data stamped")
    }

    // MARK: - Restore data dari Firestore (dipanggil setiap ContentView muncul, idempotent-safe)
    private func restoreCloudDataIfNeeded() async {
        guard let firebaseUser = Auth.auth().currentUser else { return }
        let context = container.mainContext

        // Cek apakah user sudah tergabung keluarga (familyCode) via UserProfile lokal
        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = (try? context.fetch(descriptor)) ?? []
        let currentProfile = profiles.first(where: { $0.firebaseUid == firebaseUser.uid })

        do {
            if let familyCode = currentProfile?.familyCode, !familyCode.isEmpty {
                print("☁️ Restoring data keluarga: \(familyCode)")
                try await SmartSyncService.shared.pullFamilyData(
                    familyCode: familyCode,
                    modelContext: context
                )
            } else {
                print("☁️ Restoring data personal: \(firebaseUser.uid)")
                try await SmartSyncService.shared.pullPersonalData(
                    firebaseUid: firebaseUser.uid,
                    modelContext: context
                )
            }
        } catch {
            print("❌ Restore data gagal: \(error.localizedDescription)")
        }
    }
}
