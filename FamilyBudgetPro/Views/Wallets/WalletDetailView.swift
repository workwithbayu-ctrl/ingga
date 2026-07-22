import SwiftUI
import SwiftData

struct WalletDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var dataService = DataService.shared

    let wallet: Wallet

    @State private var pockets: [Pocket] = []
    @State private var transactions: [Transaction] = []
    @State private var showingAddPocket = false
    @State private var showingAddTransaction = false
    @State private var showingTransferBetweenPockets = false

    var body: some View {
        ZStack {
            // Dark background
            Color(hex: "0B1220")?.ignoresSafeArea() ?? Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    walletInfoCard
                    pocketSummaryCard
                    pocketsSection
                    transactionsSection
                }
                .padding()
            }
        }
        .navigationTitle(wallet.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingAddPocket = true }) {
                        Label("Add Pocket", systemImage: "folder.badge.plus")
                            .foregroundColor(.white)
                    }
                    Button(action: { showingAddTransaction = true }) {
                        Label("Add Transaction", systemImage: "plus.circle")
                            .foregroundColor(.white)
                    }
                    Button(action: { showingTransferBetweenPockets = true }) {
                        Label("Transfer Between Pockets", systemImage: "arrow.left.arrow.right")
                            .foregroundColor(.white)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $showingAddPocket) {
            AddPocketView()
        }
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionView()
        }
        .sheet(isPresented: $showingTransferBetweenPockets) {
            Text("Transfer Between Pockets")
                .font(.title)
                .foregroundColor(.white)
        }
        .onAppear {
            loadData()
        }
    }

    private var walletInfoCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Wallet Balance")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))

                    Text(formattedCurrency(wallet.balance))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }

                Spacer()

                Image(systemName: walletIcon)
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: "64B4FF") ?? .blue)
            }

            Divider()
                .background(Color.white.opacity(0.1))

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total in Pockets")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))

                    let pocketTotal = dataService.totalPocketBalance(for: wallet.id)
                    Text(formattedCurrency(pocketTotal))
                        .font(.headline)
                        .foregroundColor(.green)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Available")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))

                    let pocketTotal = dataService.totalPocketBalance(for: wallet.id)
                    let available = wallet.balance - pocketTotal
                    Text(formattedCurrency(available))
                        .font(.headline)
                        .foregroundColor(available >= 0 ? .white : .red)
                }
            }
        }
        .padding()
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
        .cornerRadius(28)
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
    }

    private var pocketSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pockets Overview")
                .font(.headline)
                .foregroundColor(.white)

            HStack(spacing: 16) {
                StatCard(
                    title: "Total Pockets",
                    value: "\(pockets.count)",
                    icon: "folder.fill",
                    color: .blue
                )

                StatCard(
                    title: "Pocket Balance",
                    value: formattedCurrency(dataService.totalPocketBalance(for: wallet.id)),
                    icon: "creditcard.fill",
                    color: .green
                )
            }
        }
        .padding()
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
        .cornerRadius(28)
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
    }

    private var pocketsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Pockets")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Button(action: { showingAddPocket = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color(hex: "64B4FF") ?? .blue)
                }
            }

            if pockets.isEmpty {
                emptyStateView(
                    icon: "folder",
                    title: "No Pockets Yet",
                    message: "Create pockets to organize your budget"
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(pockets) { pocket in
                        PocketRowView(pocket: pocket)
                    }
                }
            }
        }
        .padding()
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
        .cornerRadius(28)
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
    }

    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Button(action: { showingAddTransaction = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color(hex: "64B4FF") ?? .blue)
                }
            }

            if transactions.isEmpty {
                emptyStateView(
                    icon: "list.bullet.rectangle",
                    title: "No Transactions",
                    message: "Add your first transaction to this wallet"
                )
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(transactions.prefix(10)) { transaction in
                        TransactionRowView(transaction: transaction)
                    }
                }
            }
        }
        .padding()
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
        .cornerRadius(28)
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
    }

    private func emptyStateView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.3))

            Text(title)
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))

            Text(message)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var walletIcon: String {
        switch wallet.type.lowercased() {
        case "cash": return "banknote.fill"
        case "bank": return "building.columns.fill"
        case "ewallet": return "iphone"
        case "savings": return "piggy.bank.fill"
        default: return "wallet.bifold.fill"
        }
    }

    private func loadData() {
        pockets = dataService.fetchPockets(for: wallet.id)
        transactions = dataService.fetchTransactions().filter { $0.wallet?.id == wallet.id }
    }

    private func formattedCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "IDR"
        formatter.locale = Locale(identifier: "id_ID")
        return formatter.string(from: NSNumber(value: value)) ?? "Rp 0"
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.15))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct PocketRowView: View {
    let pocket: Pocket

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(pocketColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: pocket.icon)
                    .foregroundColor(pocketColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(pocket.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Text(formattedCurrency(pocket.balance))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            Text(pocket.formattedProgress)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color(hex: "64B4FF") ?? .blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "64B4FF")?.opacity(0.1) ?? Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }

    private var pocketColor: Color {
        colorFromHex(pocket.colorHex)
    }

    private func formattedCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "IDR"
        formatter.locale = Locale(identifier: "id_ID")
        return formatter.string(from: NSNumber(value: value)) ?? "Rp 0"
    }
}

struct TransactionRowView: View {
    let transaction: Transaction

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(transactionColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: transactionIcon)
                    .foregroundColor(transactionColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.note)
                    .font(.subheadline)
                    .lineLimit(1)
                    .foregroundColor(.white)

                Text(formattedDate(transaction.date))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            Text(formattedCurrency(transaction.amount))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(transactionColor)
        }
        .padding(.vertical, 8)
    }

    private var transactionColor: Color {
        switch transaction.type {
        case .income: return .green
        case .expense: return .red
        case .transfer: return Color(hex: "64B4FF") ?? .blue
        }
    }

    private var transactionIcon: String {
        switch transaction.type {
        case .income: return "arrow.down.left"
        case .expense: return "arrow.up.right"
        case .transfer: return "arrow.left.arrow.right"
        }
    }

    private func formattedCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "IDR"
        formatter.locale = Locale(identifier: "id_ID")
        return formatter.string(from: NSNumber(value: value)) ?? "Rp 0"
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "id_ID")
        return formatter.string(from: date)
    }
}

private func colorFromHex(_ hex: String) -> Color {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a, r, g, b: UInt64
    switch hex.count {
    case 3:
        (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6:
        (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8:
        (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
        (a, r, g, b) = (1, 1, 1, 0)
    }

    return Color(
        .sRGB,
        red: Double(r) / 255,
        green: Double(g) / 255,
        blue: Double(b) / 255,
        opacity: Double(a) / 255
    )
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Wallet.self, Pocket.self, Transaction.self, configurations: config)

    let wallet = Wallet(name: "Main Wallet", type: .cash, balance: 5000000)

    NavigationStack {
        WalletDetailView(wallet: wallet)
    }
    .modelContainer(container)
}
