import Foundation
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import SwiftData
import Combine
import FirebaseFirestore


// MARK: - Auth Service

class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isAuthenticated: Bool = false

    private let db = Firestore.firestore()

    private init() {}

    /// ⭐ FIX: sebelumnya cuma `registerWithEmail()` (signup) yang membuat record `User` lokal
    /// (dipakai untuk atribusi "siapa yang input transaksi ini" di AddIncome/AddExpense/Transfer).
    /// Akun yang login lewat `signIn`/`signInWithGoogle` (bukan signup baru) tidak pernah
    /// mendapat record ini, sehingga `currentUser` selalu nil dan muncul error
    /// "User tidak ditemukan" saat menyimpan transaksi. Fungsi ini "menyembuhkan" akun lama
    /// dengan membuat record User lokal kalau belum ada, dipanggil setiap kali login berhasil.
    private func ensureLocalUserExists(
        email: String,
        displayName: String,
        modelContext: ModelContext
    ) {
        let descriptor = FetchDescriptor<User>()
        let existingUsers = (try? modelContext.fetch(descriptor)) ?? []

        // Sudah ada record untuk email ini -> tidak perlu dibuat lagi
        if existingUsers.contains(where: { $0.email == email }) { return }

        // Tebak peran secara wajar: kalau belum ada user sama sekali -> suami (default pertama),
        // kalau sudah ada 1 user lain -> istri (anggota kedua rumah tangga)
        let role: UserRole = existingUsers.isEmpty ? .husband : .wife

        let localUser = User(
            name: displayName.isEmpty ? email : displayName,
            email: email,
            password: "",
            role: role
        )
        modelContext.insert(localUser)
        try? modelContext.save()
        print("🩹 Self-heal: dibuat record User lokal untuk \(email) (role: \(role.rawValue))")
    }

    // MARK: - Google Sign In
    func signInWithGoogle(
        presenting: UIViewController,
        modelContext: ModelContext
    ) async {
        isLoading = true
        defer { isLoading = false }

        do {
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                errorMessage = "Firebase tidak terkonfigurasi"
                return
            }

            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config

            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: presenting
            )

            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Gagal mendapatkan token"
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )

            let authResult = try await Auth.auth().signIn(with: credential)
            let firebaseUser = authResult.user

            let profile = await saveUserProfile(
                firebaseUser: firebaseUser,
                modelContext: modelContext
            )
            ensureLocalUserExists(
                email: firebaseUser.email ?? "",
                displayName: firebaseUser.displayName ?? "",
                modelContext: modelContext
            )

            await FamilyService.shared.checkCurrentFamily(
                modelContext: modelContext
            )

            AuthStateManager.shared.didLogin(user: profile)

            isAuthenticated = true
            successMessage = "Login berhasil!"

        } catch {
            isAuthenticated = false
            errorMessage = "Login gagal: \(error.localizedDescription)"
        }
    }

    // MARK: - Email Sign In
    func signInWithEmail(
        email: String,
        password: String,
        modelContext: ModelContext
    ) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let authResult = try await Auth.auth().signIn(
                withEmail: email,
                password: password
            )
            let firebaseUser = authResult.user

            let profile = await saveUserProfile(
                firebaseUser: firebaseUser,
                modelContext: modelContext
            )
            ensureLocalUserExists(
                email: firebaseUser.email ?? email,
                displayName: firebaseUser.displayName ?? "",
                modelContext: modelContext
            )
            await FamilyService.shared.checkCurrentFamily(
                modelContext: modelContext
            )
            AuthStateManager.shared.didLogin(user: profile)

            isAuthenticated = true
            successMessage = "Login berhasil!"
        } catch {
            isAuthenticated = false
            errorMessage = "Login gagal: \(error.localizedDescription)"
        }
    }

    // MARK: - Register
    func registerWithEmail(
        email: String,
        password: String,
        displayName: String,
        role: UserRole,
        modelContext: ModelContext
    ) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let authResult = try await Auth.auth().createUser(
                withEmail: email,
                password: password
            )
            let firebaseUser = authResult.user

            let changeRequest = firebaseUser.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()

            let profile = await saveUserProfile(
                firebaseUser: firebaseUser,
                modelContext: modelContext
            )
            AuthStateManager.shared.didLogin(user: profile)

            // Buat/perbarui record User lokal (dipakai untuk atribusi transaksi: Transfer, AddIncome, AddExpense, dll)
            let userDescriptor = FetchDescriptor<User>()
            if let existingUsers = try? modelContext.fetch(userDescriptor),
               let existing = existingUsers.first(where: { $0.email == email }) {
                existing.name = displayName
                existing.role = role
                existing.isActive = true
            } else {
                let localUser = User(
                    name: displayName,
                    email: email,
                    password: "",
                    role: role
                )
                modelContext.insert(localUser)
            }
            try? modelContext.save()

            isAuthenticated = true
            successMessage = "Registrasi berhasil!"
        } catch {
            isAuthenticated = false
            errorMessage = "Registrasi gagal: \(error.localizedDescription)"
        }
    }

    // MARK: - Logout
    func logout(modelContext: ModelContext) async {
        print("🚪 AuthService.logout() started")
        isLoading = true
        defer { isLoading = false }

        // ⭐ FIX: sebelumnya syncPendingRecords() (panggilan jaringan ke Firestore) dipanggil
        // di sini dan DI-AWAIT sebelum melanjutkan. Kalau koneksi bermasalah (lihat log
        // sebelumnya: permission denied, no network route), panggilan ini bisa menggantung
        // lama, membuat SELURUH proses logout ikut macet menunggunya.
        // Logout adalah perubahan status LOKAL — harus selalu berhasil instan, apapun
        // kondisi jaringan. Data yang belum ter-sync tetap aman tersimpan lokal (LocalSyncRecord)
        // dan akan otomatis disinkronkan nanti lewat auto-sync biasa saat online kembali.

        if let user = Auth.auth().currentUser {
            let descriptor = FetchDescriptor<UserProfile>()
            if let profiles = try? modelContext.fetch(descriptor) {
                if let profile = profiles.first(where: { $0.firebaseUid == user.uid }) {
                    profile.isLoggedIn = false
                    profile.lastSyncAt = Date()
                    try? modelContext.save()
                }
            }
        }

        GIDSignIn.sharedInstance.signOut()

        // Auth.auth().signOut() bisa throw (mis. masalah keychain/jaringan).
        // Kalau itu terjadi, JANGAN biarkan user terjebak di dalam app — status logout
        // lokal (isAuthenticated, AuthStateManager) tetap harus di-set, apapun hasilnya.
        do {
            try Auth.auth().signOut()
        } catch {
            print("⚠️ Auth.auth().signOut() gagal (diabaikan, tetap logout lokal): \(error.localizedDescription)")
        }

        AuthStateManager.shared.didLogout()
        isAuthenticated = false
        successMessage = "Berhasil keluar"
        print("🚪 AuthService.logout() finished — isAuthenticated = false")
    }

    // MARK: - Save User Profile
    private func saveUserProfile(
        firebaseUser: FirebaseAuth.User,
        modelContext: ModelContext
    ) async -> UserProfile {
        let descriptor = FetchDescriptor<UserProfile>()

        if let profiles = try? modelContext.fetch(descriptor),
           let existing = profiles.first(where: { $0.firebaseUid == firebaseUser.uid }) {
            existing.email = firebaseUser.email ?? ""
            existing.displayName = firebaseUser.displayName ?? ""
            existing.photoURL = firebaseUser.photoURL?.absoluteString
            existing.isLoggedIn = true
            existing.lastSyncAt = Date()
            try? modelContext.save()
            return existing
        }

        let newProfile = UserProfile(
            firebaseUid: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            displayName: firebaseUser.displayName ?? "Pengguna",
            photoURL: firebaseUser.photoURL?.absoluteString,
            authProvider: "google"
        )
        newProfile.isLoggedIn = true
        modelContext.insert(newProfile)
        try? modelContext.save()

        try? await db.collection("users").document(firebaseUser.uid).setData(
            newProfile.toFirestoreData(),
            merge: true
        )

        return newProfile
    }

    // MARK: - Wrapper Methods for LoginView Compatibility

    func signIn(email: String, password: String, modelContext: ModelContext) async {
        await signInWithEmail(email: email, password: password, modelContext: modelContext)
    }

    func signUp(email: String, password: String, displayName: String, role: UserRole, modelContext: ModelContext) async {
        await registerWithEmail(email: email, password: password, displayName: displayName, role: role, modelContext: modelContext)
    }


    func signInWithGoogle(modelContext: ModelContext) async {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Tidak dapat menemukan view controller"
            return
        }
        await signInWithGoogle(presenting: rootViewController, modelContext: modelContext)
    }

}
