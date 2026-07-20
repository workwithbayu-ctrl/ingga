import SwiftData
import Foundation

@Model
class Category {
    var id: UUID
    var name: String
    var type: TransactionType
    var icon: String
    var colorHex: String
    var parentCategory: String? // ⭐ Nama kategori parent (untuk sub-kategori)
    var isDefault: Bool
    var createdAt: Date

    @Relationship(inverse: \Transaction.category)
    var transactions: [Transaction]?

    init(name: String, type: TransactionType, icon: String, colorHex: String, parentCategory: String? = nil, isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.icon = icon
        self.colorHex = colorHex
        self.parentCategory = parentCategory
        self.isDefault = isDefault
        self.createdAt = Date()
    }

    // ⭐ Helper computed properties
    var isSubcategory: Bool {
        parentCategory != nil
    }

    var displayName: String {
        isSubcategory ? "\(parentCategory!) › \(name)" : name
    }
}

enum TransactionType: String, Codable, CaseIterable {
    case income = "Pemasukan"
    case expense = "Pengeluaran"
    case transfer = "Transfer"
}

// MARK: - Default Categories
extension Category {
    // ⭐ INCOME CATEGORIES (flat, no subcategories)
    static let incomeCategories: [(name: String, icon: String, color: String)] = [
        ("Gaji", "dollarsign.circle.fill", "#34C759"),
        ("Freelance", "laptopcomputer", "#5856D6"),
        ("Bisnis", "briefcase.fill", "#FF9500"),
        ("Bonus", "gift.fill", "#FF3B30"),
        ("Investasi", "chart.line.uptrend.xyaxis", "#AF52DE"),
        ("Lainnya", "ellipsis.circle.fill", "#8E8E93"),
    ]

    // ⭐ EXPENSE CATEGORIES — Hierarchical structure
    // Format: (name, icon, color, parent)
    // parent = nil → main category
    // parent = "Name" → subcategory of that main category
    static let expenseCategories: [(name: String, icon: String, color: String, parent: String?)] = [

        // ===== RUMAH TANGGA (Parent) =====
        ("Rumah Tangga", "house.fill", "#FF9500", nil),
        ("Listrik", "bolt.fill", "#FFD60A", "Rumah Tangga"),
        ("Air", "drop.fill", "#64D2FF", "Rumah Tangga"),
        ("Belanja Masak", "carrot.fill", "#FF6B22", "Rumah Tangga"),

        // ===== BELANJA (Parent) =====
        ("Belanja", "bag.fill", "#FF9500", nil),
        ("Belanja Makeup", "face.smiling.fill", "#FF2D92", "Belanja"),
        ("Baju & Sepatu", "tshirt.fill", "#5856D6", "Belanja"),
        ("Sabun", "sparkles", "#BF5AF2", "Belanja"),
        ("Handbody", "hand.raised.fill", "#FF6482", "Belanja"),
        ("Toothpaste", "mouth.fill", "#5E5CE6", "Belanja"),
        ("Lainnya (Makeup)", "ellipsis", "#8E8E93", "Belanja"),

        // ===== KEPERLUAN CIA (Parent) =====
        ("Keperluan Cia", "figure.child", "#FF3B30", nil),
        ("Pampers", "rectangle.fill", "#34C759", "Keperluan Cia"),
        ("Susu", "cup.and.saucer.fill", "#64D2FF", "Keperluan Cia"),
        ("Obat", "cross.case.fill", "#FF3B30", "Keperluan Cia"),

        // ===== ART (Parent) =====
        ("ART", "person.2.fill", "#AF52DE", nil),
        ("ART (Bu Inul)", "person.fill", "#FF9500", "ART"),
        ("ART (Bu Lilik)", "person.fill.checkmark", "#AF52DE", "ART"),

        // ===== TRANSPORTASI (Parent) =====
        ("Transportasi", "car.fill", "#007AFF", nil),
        ("Bensin", "fuel.pump.fill", "#34C759", "Transportasi"),
        ("Ojek Online", "bicycle", "#00C7BE", "Transportasi"),

        // ===== MAIN CATEGORIES (No subcategories) =====
        ("Makanan", "fork.knife", "#FF6B22", nil),
        ("Pendidikan", "graduationcap.fill", "#5856D6", nil),
        ("Kesehatan", "heart.fill", "#FF2D55", nil),
        ("Hiburan", "tv.fill", "#AF52DE", nil),
        ("Lainnya", "ellipsis.circle.fill", "#8E8E93", nil),
    ]

    // ⭐ Helper: Get all parent categories
    static var parentExpenseCategories: [(name: String, icon: String, color: String)] {
        expenseCategories
            .filter { $0.parent == nil }
            .map { ($0.name, $0.icon, $0.color) }
    }

    // ⭐ Helper: Get subcategories for a parent
    static func subcategories(for parentName: String) -> [(name: String, icon: String, color: String)] {
        expenseCategories
            .filter { $0.parent == parentName }
            .map { ($0.name, $0.icon, $0.color) }
    }
}
