import Foundation
import SwiftData

@Model
class UserProfile {
    @Attribute(.unique) var id: UUID
    var firebaseUid: String?
    var email: String
    var displayName: String
    var photoURL: String?
    var authProvider: String      // "email", "google"
    var createdAt: Date
    var lastSyncAt: Date?
    var isLoggedIn: Bool

    // ⭐ FAMILY SHARING FIELDS
    var familyCode: String?
    var familyRole: String?
    
    init(firebaseUid: String? = nil, email: String, displayName: String, photoURL: String? = nil, authProvider: String = "email", familyCode: String? = nil, familyRole: String? = nil) {
        self.id = UUID()
        self.firebaseUid = firebaseUid
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.authProvider = authProvider
        self.createdAt = Date()
        self.lastSyncAt = nil
        self.isLoggedIn = true
        self.familyCode = familyCode
        self.familyRole = familyRole
    }
}
