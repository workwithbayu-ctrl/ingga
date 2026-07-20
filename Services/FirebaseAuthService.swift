import Foundation
import Combine
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

class FirebaseAuthService: ObservableObject {
    static let shared = FirebaseAuthService()

    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var authError: String?
    @Published var errorMessage: String?

    private lazy var db: Firestore = {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        return Firestore.firestore()
    }()

    private init() {
        // Safe initialization - don't access Auth.auth() here
        print("🚀 FirebaseAuthService initialized")
    }

    private func ensureFirebaseConfigured() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("✅ Firebase configured on demand")
        }
    }

    // MARK: - Sign Up
    func signUp(email: String, password: String, name: String, role: UserRole = .husband) async -> User? {
        ensureFirebaseConfigured()
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let firebaseUser = result.user

            let user = User(name: name, email: email, password: password, role: role, colorHex: "#007AFF")
            saveUserToFirestore(user: user, firebaseUID: firebaseUser.uid)
            return user
        } catch {
            self.authError = error.localizedDescription
            self.errorMessage = error.localizedDescription
            print("❌ Sign up error: \(error)")
            return nil
        }
    }

    // Legacy completion-based version
    func signUp(email: String, password: String, name: String, completion: @escaping (Result<User, Error>) -> Void) {
        ensureFirebaseConfigured()
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.authError = error.localizedDescription
                self?.errorMessage = error.localizedDescription
                completion(.failure(error))
                return
            }
            guard let firebaseUser = result?.user else {
                completion(.failure(NSError(domain: "FirebaseAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "User creation failed"])))
                return
            }

            let user = User(name: name, email: email, password: password, role: .husband, colorHex: "#007AFF")
            self?.saveUserToFirestore(user: user, firebaseUID: firebaseUser.uid)
            completion(.success(user))
        }
    }

    // MARK: - Sign In
    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        ensureFirebaseConfigured()
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.authError = error.localizedDescription
                self?.errorMessage = error.localizedDescription
                completion(.failure(error))
                return
            }
            guard let firebaseUser = result?.user else {
                completion(.failure(NSError(domain: "FirebaseAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sign in failed"])))
                return
            }

            self?.fetchUserFromFirestore(uid: firebaseUser.uid) { user in
                if let user = user {
                    completion(.success(user))
                } else {
                    completion(.failure(NSError(domain: "FirebaseAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "User data not found"])))
                }
            }
        }
    }

    // MARK: - Sign Out
    func signOut() {
        ensureFirebaseConfigured()
        do {
            try Auth.auth().signOut()
            currentUser = nil
            isAuthenticated = false
            print("✅ Signed out successfully")
        } catch {
            authError = error.localizedDescription
            print("❌ Sign out error: \(error)")
        }
    }

    // MARK: - Firestore Helpers
    private func saveUserToFirestore(user: User, firebaseUID: String) {
        let userData: [String: Any] = [
            "uid": firebaseUID,
            "name": user.name,
            "email": user.email,
            "role": user.role.rawValue,
            "colorHex": user.colorHex,
            "createdAt": Timestamp(date: Date())
        ]
        db.collection("users").document(firebaseUID).setData(userData) { error in
            if let error = error {
                print("❌ Error saving user: \(error)")
            } else {
                print("✅ User saved to Firestore")
            }
        }
    }

    private func fetchUserFromFirestore(uid: String, completion: @escaping (User?) -> Void) {
        db.collection("users").document(uid).getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                completion(nil)
                return
            }

            let name = data["name"] as? String ?? ""
            let email = data["email"] as? String ?? ""
            let roleString = data["role"] as? String ?? "husband"
            let role = UserRole(rawValue: roleString) ?? .husband
            let colorHex = data["colorHex"] as? String ?? "#007AFF"

            let user = User(name: name, email: email, password: "", role: role, colorHex: colorHex)
            completion(user)
        }
    }

    // MARK: - Password Reset
    func sendPasswordReset(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        ensureFirebaseConfigured()
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    // MARK: - Auth State Listener
    func startAuthStateListener() {
        ensureFirebaseConfigured()
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            if let firebaseUser = firebaseUser {
                self?.fetchUserFromFirestore(uid: firebaseUser.uid) { user in
                    self?.currentUser = user
                    self?.isAuthenticated = user != nil
                }
            } else {
                self?.currentUser = nil
                self?.isAuthenticated = false
            }
        }
    }

    // MARK: - Family Management
    func createFamily() async -> String? {
        ensureFirebaseConfigured()
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            print("❌ User not authenticated")
            return nil
        }

        let familyID = UUID().uuidString
        let familyData: [String: Any] = [
            "id": familyID,
            "name": "My Family",
            "createdBy": currentUserID,
            "createdAt": Timestamp(date: Date()),
            "members": [currentUserID]
        ]

        do {
            try await db.collection("families").document(familyID).setData(familyData)
            try await db.collection("users").document(currentUserID).updateData(["familyID": familyID])
            print("✅ Family created: \(familyID)")
            return familyID
        } catch {
            print("❌ Error creating family: \(error)")
            return nil
        }
    }

    func joinFamily(familyID: String) async {
        ensureFirebaseConfigured()
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            print("❌ User not authenticated")
            return
        }

        do {
            let snapshot = try await db.collection("families").document(familyID).getDocument()
            guard snapshot.exists else {
                print("❌ Family not found")
                return
            }

            try await db.collection("families").document(familyID).updateData([
                "members": FieldValue.arrayUnion([currentUserID])
            ])
            try await db.collection("users").document(currentUserID).updateData(["familyID": familyID])
            print("✅ Joined family: \(familyID)")
        } catch {
            print("❌ Error joining family: \(error)")
        }
    }
}
