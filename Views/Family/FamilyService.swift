import Foundation
import FirebaseFirestore
import FirebaseAuth
import SwiftData
import Combine


// MARK: - Family Service

class FamilyService: ObservableObject {
    static let shared = FamilyService()

    @Published var currentFamily: FamilyGroup?
    @Published var familyMembers: [FamilyMember] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var hasFamily: Bool = false

    private let db = Firestore.firestore()
    private var familyListener: ListenerRegistration?
    private var membersListener: ListenerRegistration?

    private init() {}

    // MARK: - Create Family
    func createFamily(name: String, modelContext: ModelContext) async {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "User tidak terautentikasi"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let familyCode = FamilyGroup.generateCode()
            let familyId = UUID().uuidString

            let familyData: [String: Any] = [
                "id": familyId,
                "familyCode": familyCode,
                "name": name,
                "createdBy": user.uid,
                "createdAt": Timestamp(date: Date()),
                "isActive": true,
                "members": [
                    [
                        "id": user.uid,
                        "name": user.displayName ?? "Pemilik",
                        "email": user.email ?? "",
                        "role": "owner",
                        "joinedAt": Timestamp(date: Date()),
                        "avatarColor": "#007AFF"
                    ]
                ]
            ]

            try await db.collection("families").document(familyCode).setData(familyData)

            // Save locally
            let family = FamilyGroup(name: name, createdBy: user.uid)
        family.familyCode = familyCode
            modelContext.insert(family)
            try modelContext.save()

            // Update user profile
            await updateUserFamilyCode(familyCode: familyCode, role: "owner", modelContext: modelContext)

            currentFamily = family
            hasFamily = true
            successMessage = "Keluarga \(name) berhasil dibuat! Kode: \(familyCode)"

            // Start real-time listeners
            startFamilyListeners(familyCode: familyCode)

        } catch {
            errorMessage = "Gagal membuat keluarga: \(error.localizedDescription)"
        }
    }

    // MARK: - Join Family
    func joinFamily(code: String, modelContext: ModelContext) async {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "User tidak terautentikasi"
            return
        }

        isLoading = true
        defer { isLoading = false }

        let upperCode = code.uppercased().trimmingCharacters(in: .whitespaces)

        do {
            let docRef = db.collection("families").document(upperCode)
            let snapshot = try await docRef.getDocument()

            guard snapshot.exists else {
                errorMessage = "Kode keluarga tidak ditemukan"
                return
            }

            guard let data = snapshot.data(), data["isActive"] as? Bool == true else {
                errorMessage = "Keluarga tidak aktif"
                return
            }

            // Check if already member
            if let members = data["members"] as? [[String: Any]],
               members.contains(where: { ($0["id"] as? String) == user.uid }) {
                errorMessage = "Anda sudah menjadi anggota keluarga ini"
                return
            }

            // Add member
            let newMember: [String: Any] = [
                "id": user.uid,
                "name": user.displayName ?? "Anggota",
                "email": user.email ?? "",
                "role": "member",
                "joinedAt": Timestamp(date: Date()),
                "avatarColor": "#FF2D92"
            ]

            try await docRef.updateData([
                "members": FieldValue.arrayUnion([newMember])
            ])

            // Save locally
            let family = FamilyGroup(
                name: data["name"] as? String ?? "Keluarga",
                createdBy: data["createdBy"] as? String ?? "",
                familyCode: upperCode
            )
            modelContext.insert(family)
            try modelContext.save()

            // Update user profile
            await updateUserFamilyCode(familyCode: upperCode, role: "member", modelContext: modelContext)

            currentFamily = family
            hasFamily = true
            successMessage = "Berhasil bergabung dengan keluarga!"

            // Start real-time listeners
            startFamilyListeners(familyCode: upperCode)

            // Pull family data
            try? await SmartSyncService.shared.pullFamilyData(familyCode: upperCode, modelContext: modelContext)

        } catch {
            errorMessage = "Gagal bergabung: \(error.localizedDescription)"
        }
    }

    // MARK: - Leave Family
    func leaveFamily(modelContext: ModelContext) async {
        guard let user = Auth.auth().currentUser else { return }
        guard let familyCode = currentFamily?.familyCode else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let docRef = db.collection("families").document(familyCode)
            let snapshot = try await docRef.getDocument()

            guard let data = snapshot.data(),
                  var members = data["members"] as? [[String: Any]] else { return }

            members.removeAll { ($0["id"] as? String) == user.uid }

            if members.isEmpty {
                // Delete family if no members left
                try await docRef.delete()
            } else {
                try await docRef.updateData(["members": members])
            }

            // Clear local data
            if let family = currentFamily {
                modelContext.delete(family)
            }

            // Clear family code from profile
            await updateUserFamilyCode(familyCode: nil, role: nil, modelContext: modelContext)

            // Stop listeners
            stopFamilyListeners()

            currentFamily = nil
            familyMembers = []
            successMessage = "Berhasil keluar dari keluarga"

        } catch {
            errorMessage = "Gagal keluar: \(error.localizedDescription)"
        }
    }

    // MARK: - Check Current Family (Call on App Launch)
    func checkCurrentFamily(modelContext: ModelContext) async {
        guard let user = Auth.auth().currentUser else { return }

        let descriptor = FetchDescriptor<UserProfile>()

        guard let profiles = try? modelContext.fetch(descriptor),
              let profile = profiles.first(where: { $0.firebaseUid == user.uid }),
              let familyCode = profile.familyCode else { return }

        do {
            // Fetch family data from Firestore
            let docRef = db.collection("families").document(familyCode)
            let snapshot = try await docRef.getDocument()

            guard snapshot.exists,
                  let data = snapshot.data(),
                  data["isActive"] as? Bool == true else {
                // Family no longer exists or inactive
                await updateUserFamilyCode(familyCode: nil, role: nil, modelContext: modelContext)
                return
            }

            // Update local family
            let family = FamilyGroup(
                name: data["name"] as? String ?? "Keluarga",
                createdBy: data["createdBy"] as? String ?? "",
                familyCode: familyCode
            )

            // Check if already exists locally
            let familyDescriptor = FetchDescriptor<FamilyGroup>(
                predicate: #Predicate { $0.familyCode == familyCode }
            )
            if let existing = try? modelContext.fetch(familyDescriptor).first {
                currentFamily = existing
            hasFamily = true
            } else {
                modelContext.insert(family)
                try? modelContext.save()
                currentFamily = family
            hasFamily = true
            }

            // Parse members
            parseMembers(from: data)

            // Start real-time listeners
            startFamilyListeners(familyCode: familyCode)

        } catch {
            print("Failed to fetch family: \(error)")
        }
    }

    // MARK: - Real-time Listeners
    private func startFamilyListeners(familyCode: String) {
        stopFamilyListeners()

        // Listen to family document changes
        familyListener = db.collection("families").document(familyCode)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let data = snapshot?.data() else { return }
                self.parseMembers(from: data)
            }

        // Listen to transactions
        membersListener = db.collection("families").document(familyCode)
            .collection("transactions")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                print("📡 Real-time: \(documents.count) transactions updated")
            }
    }

    private func stopFamilyListeners() {
        familyListener?.remove()
        membersListener?.remove()
        familyListener = nil
        membersListener = nil
    }

    // MARK: - Helper Methods
    private func parseMembers(from data: [String: Any]) {
        guard let membersData = data["members"] as? [[String: Any]] else { return }

        familyMembers = membersData.compactMap { memberData in
            guard let id = memberData["id"] as? String,
                  let name = memberData["name"] as? String,
                  let email = memberData["email"] as? String,
                  let roleStr = memberData["role"] as? String,
                  let role = FamilyRole(rawValue: roleStr) else { return nil }

            return FamilyMember(
                id: id,
                name: name,
                email: email,
                role: role,
                joinedAt: (memberData["joinedAt"] as? Timestamp)?.dateValue() ?? Date(),
                avatarColor: memberData["avatarColor"] as? String ?? "#007AFF"
            )
        }
    }

    private func updateUserFamilyCode(familyCode: String?, role: String?, modelContext: ModelContext) async {
        guard let user = Auth.auth().currentUser else { return }

        let descriptor = FetchDescriptor<UserProfile>()

        if let profiles = try? modelContext.fetch(descriptor),
           let profile = profiles.first(where: { $0.firebaseUid == user.uid }) {
            profile.familyCode = familyCode
            profile.familyRole = role
            try? modelContext.save()

            // Update Firestore
            var updateData: [String: Any] = [:]
            if let code = familyCode {
                updateData["familyCode"] = code
            } else {
                updateData["familyCode"] = NSNull()
            }
            if let r = role {
                updateData["familyRole"] = r
            } else {
                updateData["familyRole"] = NSNull()
            }

            try? await db.collection("users").document(user.uid).updateData(updateData)
        }
    }

    // MARK: - Share Code
    func shareFamilyCode() -> String {
        guard let code = currentFamily?.familyCode else { return "" }
        return """
        🏠 Bergabung dengan keluarga saya di FamilyBudgetPro!

        Kode Keluarga: \(code)

        Download FamilyBudgetPro dan masukkan kode ini di menu Berbagi Keluarga.
        """
    }
}
