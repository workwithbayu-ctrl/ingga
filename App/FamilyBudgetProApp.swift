import SwiftUI
import SwiftData

@main
struct FamilyBudgetProApp: App {
    @StateObject private var dataService = DataService.shared
    @State private var isLoggedIn: Bool = false
    @State private var showSplash: Bool = true
    @State private var isDataServiceReady: Bool = false

    let container: ModelContainer

    init() {
        let wasLoggedIn = UserDefaults.standard.bool(forKey: "isUserLoggedIn")
        let rememberMe = UserDefaults.standard.bool(forKey: "rememberMe")
        print("🔍 App init - wasLoggedIn: \(wasLoggedIn), rememberMe: \(rememberMe)")

        let schema = Schema([
            User.self,
            Category.self,
            Wallet.self,
            Transaction.self,
            Pocket.self,
            PocketTransaction.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
            print("✅ ModelContainer created successfully")
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    LuxurySplashScreen()
                        .onAppear {
                            print("🎬 Splash screen appeared")
                            // Set container here when StateObject is installed
                            if !isDataServiceReady {
                                dataService.setModelContainer(container)
                                isDataServiceReady = true
                                print("✅ DataService container set in onAppear")
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
                                withAnimation(.easeInOut(duration: 0.8)) {
                                    showSplash = false
                                    print("🎬 Splash dismissed, isLoggedIn: \(isLoggedIn)")
                                }
                            }
                        }
                } else if isLoggedIn {
                    ContentView(onLogout: {
                        print("🚪 Logout CALLED!")
                        withAnimation(.easeInOut(duration: 0.5)) {
                            isLoggedIn = false
                            UserDefaults.standard.set(false, forKey: "isUserLoggedIn")
                            UserDefaults.standard.synchronize()
                            print("✅ Logged out, isLoggedIn = false")
                        }
                    })
                    .environmentObject(dataService)
                    .onAppear {
                        print("🏠 ContentView appeared (logged in)")
                    }
                } else {
                    LoginView(
                        onLoginSuccess: {
                            print("🚀 onLoginSuccess CALLED! Setting isLoggedIn = true")
                            withAnimation(.easeInOut(duration: 0.5)) {
                                isLoggedIn = true
                                UserDefaults.standard.set(true, forKey: "isUserLoggedIn")
                                UserDefaults.standard.synchronize()
                                print("✅ isLoggedIn set to TRUE, saved to UserDefaults")
                            }
                        }
                    )
                    .environmentObject(dataService)
                    .onAppear {
                        print("🔐 LoginView appeared")
                    }
                }
            }
            .onAppear {
                let wasLoggedIn = UserDefaults.standard.bool(forKey: "isUserLoggedIn")
                let rememberMe = UserDefaults.standard.bool(forKey: "rememberMe")
                print("🔍 onAppear - wasLoggedIn: \(wasLoggedIn), rememberMe: \(rememberMe), isLoggedIn: \(isLoggedIn)")

                if wasLoggedIn && rememberMe {
                    print("🔍 Auto-login: rememberMe is ON, setting isLoggedIn = true")
                    isLoggedIn = true
                } else if wasLoggedIn && !rememberMe {
                    print("🔍 Auto-login skipped: rememberMe is OFF")
                    UserDefaults.standard.set(false, forKey: "isUserLoggedIn")
                    UserDefaults.standard.synchronize()
                }
            }
        }
        .modelContainer(container)
    }
}
