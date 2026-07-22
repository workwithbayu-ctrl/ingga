import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction
    
    // ⭐ Pre-compute semua property di init
    private let displayTitle: String
    private let displayIcon: String
    private let displayColor: String
    private let isIncome: Bool
    private let isExpense: Bool
    private let isTransfer: Bool
    private let formattedAmount: String
    private let date: Date
    private let walletName: String?
    
    init(transaction: Transaction) {
        self.transaction = transaction
        // ⭐ Resolve semua property sekali di init
        self.displayTitle = transaction.displayTitle
        self.displayIcon = transaction.displayIcon
        self.displayColor = transaction.displayColor
        self.isIncome = transaction.isIncome
        self.isExpense = transaction.isExpense
        self.isTransfer = transaction.isTransfer
        self.formattedAmount = transaction.formattedAmount
        self.date = transaction.date
        self.walletName = transaction.wallet?.name
    }

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: displayColor)?.opacity(0.15) ?? Color.gray.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: displayIcon)
                    .font(.title3)
                    .foregroundStyle(Color(hex: displayColor) ?? .gray)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(displayTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if let walletName = walletName {
                        Text(walletName)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                    }

                    Text(date.formattedShort())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Amount
            VStack(alignment: .trailing, spacing: 2) {
                Text(isIncome ? "+" + formattedAmount : (isTransfer ? formattedAmount : "-" + formattedAmount))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(isIncome ? Color.incomeGreen : (isTransfer ? .primary : Color.expenseRed))

                if isTransfer {
                    Text("Transfer")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
    }
}
