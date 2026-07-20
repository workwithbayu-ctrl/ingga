import SwiftData
import Foundation

@Model
class Pocket {
    var id: UUID
    var name: String
    var pocketType: PocketType
    var targetAmount: Double
    var balance: Double
    var allocationPercentage: Double
    var icon: String
    var colorHex: String
    var createdAt: Date
    var isDefault: Bool
    
    // Relationship to Wallet (optional)
    var walletID: UUID?
    
    init(name: String, pocketType: PocketType, targetAmount: Double, balance: Double = 0, allocationPercentage: Double, icon: String, colorHex: String, walletID: UUID? = nil, isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.pocketType = pocketType
        self.targetAmount = targetAmount
        self.balance = balance
        self.allocationPercentage = allocationPercentage
        self.icon = icon
        self.colorHex = colorHex
        self.walletID = walletID
        self.isDefault = isDefault
        self.createdAt = Date()
    }
    
    var progress: Double {
        targetAmount > 0 ? min(balance / targetAmount, 1.0) : 0
    }
    
    var formattedProgress: String {
        let percentage = Int(progress * 100)
        return "\(percentage)%"
    }
    
    var isTargetReached: Bool {
        balance >= targetAmount
    }
}

enum PocketType: String, Codable, CaseIterable {
    case emergency = "Dana Darurat"
    case child = "Dana Anak"
    case education = "Dana Pendidikan"
    case vacation = "Dana Liburan"
    case home = "Dana Rumah"
    case investment = "Dana Investasi"
    case retirement = "Dana Pensiun"
    case dream = "Dana Impian"
    
    var displayName: String { rawValue }
    
    var icon: String {
        switch self {
        case .emergency: return "exclamationmark.triangle.fill"
        case .child: return "figure.child"
        case .education: return "graduationcap.fill"
        case .vacation: return "airplane"
        case .home: return "house.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .retirement: return "clock.fill"
        case .dream: return "star.fill"
        }
    }
    
    var color: String {
        switch self {
        case .emergency: return "#FF3B30"
        case .child: return "#FF9500"
        case .education: return "#5856D6"
        case .vacation: return "#5AC8FA"
        case .home: return "#34C759"
        case .investment: return "#AF52DE"
        case .retirement: return "#007AFF"
        case .dream: return "#FF2D55"
        }
    }
    
    var defaultTarget: Double { 1_000_000 }
    var defaultAllocation: Double { 10 }
}

// MARK: - Default Pockets
extension Pocket {
    static func defaultPockets(for wallet: Wallet? = nil) -> [Pocket] {
        PocketType.allCases.map { type in
            Pocket(
                name: type.displayName,
                pocketType: type,
                targetAmount: type.defaultTarget,
                allocationPercentage: type.defaultAllocation,
                icon: type.icon,
                colorHex: type.color,
                walletID: wallet?.id,
                isDefault: true
            )
        }
    }
}
