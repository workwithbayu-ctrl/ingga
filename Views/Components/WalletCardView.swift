import SwiftUI

struct WalletCardView: View {
    let wallet: Wallet
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: wallet.icon)
                    .font(.title2)
                    .foregroundStyle(Color(hex: wallet.colorHex) ?? .blue)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color(hex: wallet.colorHex)?.opacity(0.15) ?? Color.blue.opacity(0.15))
                    )

                Spacer()

                Text(wallet.type)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
            }

            Text(wallet.name)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(wallet.balance.formattedCurrency())
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding()
        .frame(width: 160, height: 140)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        }
    }
}

// MARK: - Animated Balance Text
struct AnimatedBalanceText: View {
    let amount: Double
    @State private var displayAmount: Double = 0

    var body: some View {
        Text(displayAmount.formattedCurrency())
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    displayAmount = amount
                }
            }
            .onChange(of: amount) { _, newValue in
                withAnimation(.easeOut(duration: 0.5)) {
                    displayAmount = newValue
                }
            }
    }
}

// MARK: - Floating Amount Animation (for income)
struct FloatingAmountView: View {
    let amount: Double
    let isIncome: Bool
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        Text((isIncome ? "+ " : "- ") + amount.formattedCurrency())
            .font(.headline)
            .foregroundStyle(isIncome ? Color.incomeGreen : Color.expenseRed)
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 1.5)) {
                    offset = -60
                    opacity = 0
                }
            }
    }
}
