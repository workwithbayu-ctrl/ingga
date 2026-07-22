import Foundation

struct FamilyMember: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let email: String
    let role: FamilyRole
    let joinedAt: Date
    let avatarColor: String
}
