import Foundation

enum FamilyRole: String, Codable {
    case owner = "owner"
    case admin = "admin"
    case member = "member"

    var displayName: String {
        switch self {
        case .owner: return "Pemilik"
        case .admin: return "Admin"
        case .member: return "Anggota"
        }
    }

    var icon: String {
        switch self {
        case .owner: return "crown.fill"
        case .admin: return "shield.fill"
        case .member: return "person.fill"
        }
    }
}
