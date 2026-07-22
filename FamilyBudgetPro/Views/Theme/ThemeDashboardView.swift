import SwiftUI
import SwiftData

// MARK: - Theme Dashboard View
struct ThemeDashboardView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.theme) var theme
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @Query private var wallets: [Wallet]
    @Query private var categories: [Category]

    @State private var selectedTimeRange: TimeRange = .week
    @State private var showingAddTransaction = false

    enum TimeRange: String, CaseIterable, Identifiable {
        case week = "Minggu"
        case month = "Bulan"
        case year = "Tahun"

        var id: String { rawValue }
    }

    var filteredTransactions: [Transaction] {
        let calendar = Calendar.current
        let now = Date()

        return allTransactions.filter { transaction in
            switch selectedTimeRange {
            case .week:
                return calendar.isDate(transaction.date, equalTo: now, toGranularity: .weekOfYear)
            case .month:
                return calendar.isDate(transaction.date, equalTo: now, toGranularity: .month)
            case .year:
                return calendar.isDate(transaction.date, equalTo: now, toGranularity: .year)
            }
        }
    }

    var totalIncome: Double {
        filteredTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    var totalExpense: Double {
        filteredTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    var totalBalance: Double {
        wallets.reduce(0) { $0 + $1.balance }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Net Worth Card (Copilot style)
                    if themeManager.selectedTheme == .copilot {
                        netWorthCard
                    }

                    // MARK: - Time Range Selector
                    timeRangeSelector

                    // MARK: - Summary Cards
                    summaryCards

                    // MARK: - Quick Actions
                    quickActions

                    // MARK: - Wallets
                    walletsSection

                    // MARK: - Recent Transactions
                    recentTransactionsSection
                }
                .padding()
            }
            .background(theme.colors.background)
            .navigationTitle("Beranda")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTransaction = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(theme.colors.primary)
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                ThemeAddTransactionView()
            }
        }
    }

    // MARK: - Net Worth Card
    private var netWorthCard: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Total Aset")
                        .font(theme.fonts.caption)
                        .foregroundStyle(theme.colors.textSecondary)

                    Spacer()

                    TrendIndicator(value: 5.2, label: "vs bulan lalu")
                }

                Text(totalBalance, format: .currency(code: "IDR"))
                    .font(theme.fonts.largeTitle)
                    .foregroundStyle(theme.colors.textPrimary)
            }
        }
    }

    // MARK: - Time Range Selector
    private var timeRangeSelector: some View {
        HStack(spacing: 8) {
            ForEach(TimeRange.allCases) { range in
                Button(action: { selectedTimeRange = range }) {
                    Text(range.rawValue)
                        .font(theme.fonts.caption)
                        .fontWeight(selectedTimeRange == range ? .semibold : .regular)
                        .foregroundStyle(selectedTimeRange == range ? .white : theme.colors.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selectedTimeRange == range ? theme.colors.primary : theme.colors.cardBackground
                        )
                        .cornerRadius(20)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Summary Cards
    private var summaryCards: some View {
        HStack(spacing: 12) {
            ThemeSummaryCard(
                title: "Pemasukan",
                amount: totalIncome,
                icon: "arrow.down.circle.fill",
                color: theme.colors.success
            )

            ThemeSummaryCard(
                title: "Pengeluaran",
                amount: totalExpense,
                icon: "arrow.up.circle.fill",
                color: theme.colors.danger
            )
        }
    }

    // MARK: - Quick Actions
    private var quickActions: some View {
        HStack(spacing: 12) {
            ThemeQuickActionButton(
                icon: "arrow.down",
                title: "Pemasukan",
                color: theme.colors.success
            ) {
                showingAddTransaction = true
            }

            ThemeQuickActionButton(
                icon: "arrow.up",
                title: "Pengeluaran",
                color: theme.colors.danger
            ) {
                showingAddTransaction = true
            }

            ThemeQuickActionButton(
                icon: "arrow.left.arrow.right",
                title: "Transfer",
                color: theme.colors.primary
            ) {
                // Navigate to transfer
            }
        }
    }

    // MARK: - Wallets Section
    private var walletsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Rekening")
                    .font(theme.fonts.title)
                    .foregroundStyle(theme.colors.textPrimary)

                Spacer()

                NavigationLink(destination: ThemeWalletListView()) {
                    Text("Lihat Semua")
                        .font(theme.fonts.caption)
                        .foregroundStyle(theme.colors.primary)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(wallets.prefix(4)) { wallet in
                        ThemedWalletCard(
                            wallet: wallet,
                            isSelected: false,
                            action: {}
                        )
                    }
                }
            }
        }
    }

    // MARK: - Recent Transactions
    private var recentTransactions: [Transaction] {
        Array(filteredTransactions.prefix(5))
    }

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Transaksi Terakhir")
                    .font(theme.fonts.title)
                    .foregroundStyle(theme.colors.textPrimary)

                Spacer()

                NavigationLink(destination: ThemeAllTransactionsView()) {
                    Text("Lihat Semua")
                        .font(theme.fonts.caption)
                        .foregroundStyle(theme.colors.primary)
                }
            }

            if filteredTransactions.isEmpty {
                emptyTransactionsView
            } else {
                recentTransactionsList
            }
        }
    }

    private var recentTransactionsList: some View {
        VStack(spacing: 8) {
            ForEach(recentTransactions) { transaction in
                NavigationLink(destination: ThemeTransactionDetailView(transaction: transaction)) {
                    ThemedTransactionRow(transaction: transaction)
                }
                .buttonStyle(.plain)

                if transaction.id != recentTransactions.last?.id {
                    Divider()
                        .padding(.leading, 56)
                }
            }
        }
        .padding(theme.cardStyle.padding)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.cardStyle.cornerRadius)
        .shadow(
            color: theme.colors.shadow,
            radius: theme.cardStyle.shadowRadius,
            x: 0,
            y: theme.cardStyle.shadowY
        )
    }

    private var emptyTransactionsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(theme.colors.textSecondary.opacity(0.5))

            Text("Belum ada transaksi")
                .font(theme.fonts.headline)
                .foregroundStyle(theme.colors.textSecondary)

            Text("Tambahkan transaksi pertama Anda")
                .font(theme.fonts.caption)
                .foregroundStyle(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.cardStyle.cornerRadius)
    }
}

// MARK: - Supporting Views (Theme-prefixed to avoid conflicts)

struct ThemeSummaryCard: View {
    @Environment(\.theme) var theme
    let title: String
    let amount: Double
    let icon: String
    let color: Color

    var body: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(color)

                    Spacer()
                }

                Text(title)
                    .font(theme.fonts.caption)
                    .foregroundStyle(theme.colors.textSecondary)

                Text(amount, format: .currency(code: "IDR"))
                    .font(theme.fonts.amountSmall)
                    .foregroundStyle(theme.colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct ThemeQuickActionButton: View {
    @Environment(\.theme) var theme
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 52, height: 52)

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(color)
                }

                Text(title)
                    .font(theme.fonts.caption)
                    .foregroundStyle(theme.colors.textPrimary)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Placeholder Views (Theme-prefixed)
struct ThemeWalletListView: View {
    var body: some View {
        Text("Wallet List")
            .navigationTitle("Rekening")
    }
}

struct ThemeAllTransactionsView: View {
    var body: some View {
        Text("All Transactions")
            .navigationTitle("Semua Transaksi")
    }
}

struct ThemeTransactionDetailView: View {
    let transaction: Transaction

    var body: some View {
        Text("Transaction Detail")
            .navigationTitle("Detail")
    }
}

// ThemeAddTransactionView is defined in ThemeMainTabView.swift
