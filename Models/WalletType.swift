import Foundation

enum WalletType: String, Codable, CaseIterable {
    case cash = "Cash"
    case bank = "Bank"
    case digital = "Digital"
    case ewallet = "E-Wallet"
}
