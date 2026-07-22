import SwiftUI
import SwiftData
import FirebaseAuth
import Combine


// MARK: - Auth State Manager (Observable for root view switching)

class AuthStateManager: ObservableObject {
    static let shared = AuthStateManager()

    @Published var isLoggedIn: Bool = false
    @Published var currentUser: UserProfile?
    @Published var isCheckingAuth: Bool = true

    private init() {
        checkAuthState()
    }

    func checkAuthState() {
        if let firebaseUser = Auth.auth().currentUser {
            isLoggedIn = true
            isCheckingAuth = false
        } else {
            isLoggedIn = false
            isCheckingAuth = false
        }
    }

    func didLogin(user: UserProfile) {
        self.currentUser = user
        self.isLoggedIn = true
    }

    func didLogout() {
        self.currentUser = nil
        self.isLoggedIn = false
    }
}

// MARK: - Root View Router
// Note: Main routing logic is in FamilyBudgetProApp.swift
// This view is kept for modularity and future use
struct RootViewRouter: View {
    @StateObject private var authState = AuthStateManager.shared

    var body: some View {
        Group {
            if authState.isCheckingAuth {
                SplashScreenView()
            } else if authState.isLoggedIn {
                Text("Use ContentView from App instead")
                    .foregroundColor(.white)
            } else {
                Text("Use LoginView from App instead")
                    .foregroundColor(.white)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authState.isLoggedIn)
    }
}

// MARK: - Splash Screen
struct SplashScreenView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Color(hex: "#0B1220")
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "wallet.bifold.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .opacity(isAnimating ? 1.0 : 0.0)

                Text("FamilyBudgetPro")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(isAnimating ? 1.0 : 0.0)

                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.cyan)
                    .opacity(isAnimating ? 1.0 : 0.0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                isAnimating = true
            }
        }
    }
}
