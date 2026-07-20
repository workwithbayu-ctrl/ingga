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
        ScrollView {
            VStack(spacing: 20) {
                walletInfoCard
                pocketSummaryCard
                pocketsSection
                transactionsSection
            }
            .padding()
        }
        .navigationTitle(wallet.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingAddPocket = true }) {
                        Label("Add Pocket", systemImage: "folder.badge.plus")
                    }
                    Button(action: { showingAddTransaction = true }) {
                        Label("Add Transaction", systemImage: "plus.circle")
                    }
                    Button(action: { showingTransferBetweenPockets = true }) {
                        Label("Transfer Between Pockets", systemImage: "arrow.left.arrow.right")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddPocket) {
            AddPocketView(wallet: wallet)
        }
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionView(wallet: wallet)
        }
        .sheet(isPresented: $showingTransferBetweenPockets) {
            Text("Transfer Between Pockets")
                .font(.title)
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
                        .foregroundColor(.secondary)
                    
                    Text(formattedCurrency(wallet.balance))
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                Image(systemName: walletIcon)
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total in Pockets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    let pocketTotal = dataService.totalPocketBalance(for: wallet.id)
                    Text(formattedCurrency(pocketTotal))
                        .font(.headline)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    let pocketTotal = dataService.totalPocketBalance(for: wallet.id)
                    let available = wallet.balance - pocketTotal
                    Text(formattedCurrency(available))
                        .font(.headline)
                        .foregroundColor(available >= 0 ? .primary : .red)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    private var pocketSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pockets Overview")
                .font(.headline)
            
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
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    private var pocketsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Pockets")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { showingAddPocket = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentColor)
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
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { showingAddTransaction = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentColor)
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
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    private func emptyStateView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
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
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
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
                
                Text(formattedCurrency(pocket.balance))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(pocket.formattedProgress)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.accentColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
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
                    .fill(transactionColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: transactionIcon)
                    .foregroundColor(transactionColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.note)
                    .font(.subheadline)
                    .lineLimit(1)
                
                Text(formattedDate(transaction.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
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
        case .transfer: return .blue
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
