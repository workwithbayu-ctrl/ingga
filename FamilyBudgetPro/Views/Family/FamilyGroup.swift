import Foundation
import SwiftData

@Model
class FamilyGroup {
    @Attribute(.unique) var id: UUID
    var familyCode: String
    var name: String
    var createdBy: String
    var createdAt: Date
    var isActive: Bool

    init(name: String, createdBy: String, familyCode: String? = nil) {
        self.id = UUID()
        self.familyCode = familyCode ?? FamilyGroup.generateCode()
        self.name = name
        self.createdBy = createdBy
        self.createdAt = Date()
        self.isActive = true
    }

    static func generateCode() -> String {
        let letters = "ABCDEFGHJKLMNPQRSTUVWXYZ"
        let numbers = "23456789"
        var code = ""
        for _ in 0..<3 { code += String(letters.randomElement()!) }
        for _ in 0..<3 { code += String(numbers.randomElement()!) }
        return code
    }
}
