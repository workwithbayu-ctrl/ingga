import SwiftData
import Foundation

@Model
class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var type: TransactionType
    var icon: String
    var colorHex: String
    var isDefault: Bool
    var isSystem: Bool      // true = cannot delete (core defaults)
    var sortOrder: Int
    var createdAt: Date

    // ⭐ FAMILY SHARING FIELDS
    var familyCode: String?
    var firebaseUid: String?

    // ⭐ NEW: Relationship-based parent (instead of String)
    @Relationship(inverse: \Category.subcategories)
    var parentCategory: Category?

    @Relationship(deleteRule: .cascade)
    var subcategories: [Category]?

    @Relationship(inverse: \Transaction.category)
    var transactions: [Transaction]?

    init(
        name: String,
        type: TransactionType,
        icon: String,
        colorHex: String,
        parentCategory: Category? = nil,
        isDefault: Bool = false,
        isSystem: Bool = false,
        sortOrder: Int = 0,
        familyCode: String? = nil,
        firebaseUid: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.icon = icon
        self.colorHex = colorHex
        self.parentCategory = parentCategory
        self.isDefault = isDefault
        self.isSystem = isSystem
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.familyCode = familyCode
        self.firebaseUid = firebaseUid
    }

    // ⭐ Helper computed properties
    var isSubcategory: Bool {
        parentCategory != nil
    }

    var displayName: String {
        isSubcategory ? "\(parentCategory!.name) › \(name)" : name
    }
}

enum TransactionType: String, Codable, CaseIterable {
    case income = "Pemasukan"
    case expense = "Pengeluaran"
    case transfer = "Transfer"
}

// MARK: - Default Categories Seed Data
extension Category {

    // ⭐ INCOME CATEGORIES (flat, editable, CRUD-able)
    static let defaultIncomeCategories: [(name: String, icon: String, color: String, isSystem: Bool)] = [
        ("Gaji", "dollarsign.circle.fill", "#34C759", true),      // System = cannot delete
        ("Bisnis", "briefcase.fill", "#FF9500", false),
        ("Freelance", "laptopcomputer", "#5856D6", false),
        ("Bonus", "gift.fill", "#FF3B30", false),
    ]

    // ⭐ EXPENSE CATEGORIES — Hierarchical with relationships
    // Parents first, then children
    static let defaultExpenseParents: [(name: String, icon: String, color: String, sortOrder: Int)] = [
        ("Rumah Tangga", "house.fill", "#FF6B6B", 1),
        ("Keperluan Anak", "figure.child", "#C9B1FF", 2),
        ("ART / Pembantu", "person.2.fill", "#A0C4FF", 3),
        ("Transportasi", "car.fill", "#FDFFB6", 4),
    ]

    static let defaultExpenseSubcategories: [(name: String, icon: String, color: String, parentName: String, sortOrder: Int)] = [
        // Rumah Tangga children
        ("Listrik", "bolt.fill", "#FFD93D", "Rumah Tangga", 1),
        ("Air", "drop.fill", "#4D96FF", "Rumah Tangga", 2),
        ("Belanja Masak", "cart.fill", "#6BCB77", "Rumah Tangga", 3),
        ("Belanja Makeup & Perlengkapan", "sparkles", "#FF9F9F", "Rumah Tangga", 4),

        // Makeup sub-subcategories (children of Belanja Makeup)
        ("Sabun", "bubble.left.fill", "#A8E6CF", "Belanja Makeup & Perlengkapan", 1),
        ("Handbody", "hand.tap.fill", "#DCEDC1", "Belanja Makeup & Perlengkapan", 2),
        ("Pasta Gigi", "mouth.fill", "#FFD3B6", "Belanja Makeup & Perlengkapan", 3),
        ("Lainnya", "ellipsis", "#FFAAA5", "Belanja Makeup & Perlengkapan", 4),

        // Keperluan Anak children
        ("Pampers", "rectangle.fill", "#B5EAD7", "Keperluan Anak", 1),
        ("Susu", "cup.and.saucer.fill", "#FFDAC1", "Keperluan Anak", 2),
        ("Obat-obatan", "cross.case.fill", "#FFB7B2", "Keperluan Anak", 3),
        ("Baju & Sepatu", "tshirt.fill", "#E2F0CB", "Keperluan Anak", 4),

        // ART children
        ("Asisten Rumah Tangga", "person.fill", "#9BF6FF", "ART / Pembantu", 1),

        // Transportasi children
        ("Bensin", "fuel.pump.fill", "#CAFFBF", "Transportasi", 1),
        ("Ojek Online", "bicycle", "#FFD6A5", "Transportasi", 2),
    ]
}
