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
                            // ⭐ Restore data dari Firestore dulu (penting setelah install ulang app,
                            // karena SwiftData lokal dikosongkan iOS setiap reinstall/delete app)
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
            // ⭐ Sumber kebenaran tunggal untuk logout: begitu AuthService.isAuthenticated
            // jadi false (proses logout selesai), root view PASTI pindah ke LoginView,
            // tidak peduli timing dismiss sheet Settings.
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
