import SwiftUI

// MARK: - Category Button
struct CategoryButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.15))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 24))
                        .foregroundStyle(categoryColor)
                }
                .overlay(
                    Circle()
                        .stroke(isSelected ? categoryColor : Color.clear, lineWidth: 3)
                )
                
                Text(category.name)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 80)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var categoryColor: Color {
        Color(hex: category.colorHex) ?? .gray
    }
}

// MARK: - Wallet Button
struct WalletButton: View {
    let wallet: Wallet
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(walletColor.opacity(0.15))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: wallet.icon)
                        .font(.system(size: 24))
                        .foregroundStyle(walletColor)
                }
                .overlay(
                    Circle()
                        .stroke(isSelected ? walletColor : Color.clear, lineWidth: 3)
                )
                
                Text(wallet.name)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 80)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var walletColor: Color {
        Color(hex: wallet.colorHex) ?? .gray
    }
}
