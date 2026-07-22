import SwiftUI

struct BalanceCardView: View {
    let totalBalance: Double
    let usableBalance: Double
    let currencyCode: String

    @State private var showTotalBalance: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Saldo (Available/Wallet only) - ALWAYS VISIBLE
            VStack(spacing: 8) {
                HStack {
                    Text("Saldo")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                    Spacer()
                }

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(currencyCode)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))

                    Text(formattedAmount(usableBalance))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    Spacer()

                    // Eye toggle button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showTotalBalance.toggle()
                        }
                    }) {
                        Image(systemName: showTotalBalance ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            // Divider with eye toggle
            if showTotalBalance {
                Divider()
                    .background(Color.white.opacity(0.2))
                    .padding(.horizontal, 20)
                    .transition(.opacity)

                // MARK: - Total Saldo (Wallet + Pocket) - HIDDEN BY DEFAULT
                VStack(spacing: 4) {
                    HStack {
                        Text("Total Saldo")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                    }

                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(currencyCode)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))

                        Text(formattedAmount(totalBalance))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white.opacity(0.95))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)

                        Spacer()
                    }

                    HStack {
                        Text("Termasuk saldo di Pocket")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.6))
                        Spacer()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "2C5282") ?? Color.blue,
                    Color(hex: "0B1220") ?? Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
    }

    private func formattedAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.decimalSeparator = ","
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}
