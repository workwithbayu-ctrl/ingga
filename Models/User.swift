import SwiftData
import Foundation

@Model
class User {
    var id: UUID
    var name: String
    var email: String
    var familyID: String?
    var role: UserRole
    var avatar: String // SF Symbol
    var colorHex: String
    var createdAt: Date
    var isActive: Bool

    var password: String

    init(name: String, email: String, password: String, role: UserRole, avatar: String = "person.fill", colorHex: String = "#007AFF") {
        self.id = UUID()
        self.name = name
        self.email = email
        self.password = password
        self.role = role
        self.avatar = avatar
        self.colorHex = colorHex
        self.createdAt = Date()
        self.isActive = true
    }
}

enum UserRole: String, Codable, CaseIterable {
    case husband = "Suami"
    case wife = "Istri"
}
