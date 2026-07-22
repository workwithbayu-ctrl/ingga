import SwiftUI
import SwiftData

// MARK: - Theme Main Tab View
struct ThemeMainTabView: View {
    @StateObject private var themeManager = ThemeManager.shared

    @State private var selectedTab = 0
    @State private var showingAddTransaction = false

    var body: some View {
        let theme: ThemeProtocol = themeManager.selectedTheme == .copilot ? CopilotTheme() : ClassicTheme()

        TabView(selection: $selectedTab) {
            ThemeDashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Beranda")
                }
                .tag(0)

            ThemeTransactionsView()
                .tabItem {
                    Image(systemName: "list.bullet.rectangle.fill")
                    Text("Transaksi")
                }
                .tag(1)

            Text("")
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Tambah")
                }
                .tag(2)

            ThemeWalletsView()
                .tabItem {
                    Image(systemName: "creditcard.fill")
                    Text("Rekening")
                }
                .tag(3)

            ThemeMoreView()
                .tabItem {
                    Image(systemName: "ellipsis.circle.fill")
                    Text("Lainnya")
                }
                .tag(4)
        }
        .environment(\.theme, theme)
        .environmentObject(themeManager)
        .tint(themeManager.selectedTheme == .copilot ? theme.colors.primary : .blue)
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == 2 {
                showingAddTransaction = true
                selectedTab = oldValue
            }
        }
        .sheet(isPresented: $showingAddTransaction) {
            ThemeAddTransactionView()
        }
    }
}

// MARK: - Theme Transactions View
struct ThemeTransactionsView: View {
    @Environment(\.theme) var theme
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]

    @State private var searchText = ""
    @State private var selectedFilter: TransactionFilter = .all

    enum TransactionFilter: String, CaseIterable, Identifiable {
        case all = "Semua"
        case income = "Pemasukan"
        case expense = "Pengeluaran"

        var id: String { rawValue }
    }

    var filteredTransactions: [Transaction] {
        var result = allTransactions

        if !searchText.isEmpty {
            result = result.filter {
                $0.note.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch selectedFilter {
        case .all:
            break
        case .income:
            result = result.filter { $0.type == .income }
        case .expense:
            result = result.filter { $0.type == .expense }
        }

        return result
    }

    var groupedTransactions: [(String, [Transaction])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredTransactions) { transaction in
            if calendar.isDateInToday(transaction.date) {
                return "Hari Ini"
            } else if calendar.isDateInYesterday(transaction.date) {
                return "Kemarin"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE, d MMMM yyyy"
                formatter.locale = Locale(identifier: "id_ID")
                return formatter.string(from: transaction.date)
            }
        }

        return grouped.sorted { group1, group2 in
            let date1 = group1.value.first?.date ?? Date()
            let date2 = group2.value.first?.date ?? Date()
            return date1 > date2
        }
    }

    var totalIncome: Double {
        filteredTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    var totalExpense: Double {
        filteredTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    searchBar
                    filterChips
                    summaryCards
                    transactionList
                }
                .padding()
            }
            .background(theme.colors.background)
            .navigationTitle("Transaksi")
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(theme.colors.textSecondary)

            TextField("Cari transaksi...", text: $searchText)
                .font(theme.fonts.body)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(theme.colors.textSecondary)
                }
            }
        }
        .padding()
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.cardStyle.cornerRadius)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TransactionFilter.allCases) { filter in
                    Button(action: { selectedFilter = filter }) {
                        Text(filter.rawValue)
                            .font(theme.fonts.caption)
                            .fontWeight(selectedFilter == filter ? .semibold : .regular)
                            .foregroundStyle(selectedFilter == filter ? .white : theme.colors.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                selectedFilter == filter ? theme.colors.primary : theme.colors.cardBackground
                            )
                            .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

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

    private var transactionList: some View {
        VStack(spacing: 16) {
            ForEach(groupedTransactions, id: \.0) { date, transactions in
                transactionGroupSection(date: date, transactions: transactions)
            }
        }
    }

    private func transactionGroupSection(date: String, transactions: [Transaction]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(date)
                .font(theme.fonts.caption)
                .fontWeight(.semibold)
                .foregroundStyle(theme.colors.textSecondary)
                .padding(.horizontal, 4)

            ThemedCard {
                VStack(spacing: 0) {
                    ForEach(transactions) { transaction in
                        ThemeTransactionRowSwipeable(transaction: transaction)

                        if transaction.id != transactions.last?.id {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Transaction Row with Swipe Actions
struct ThemeTransactionRowSwipeable: View {
    @Environment(\.modelContext) private var modelContext

    let transaction: Transaction

    var body: some View {
        ThemedTransactionRow(transaction: transaction)
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    modelContext.delete(transaction)
                } label: {
                    Label("Hapus", systemImage: "trash")
                }
            }
    }
}

// MARK: - Theme Wallets View
struct ThemeWalletsView: View {
    @Environment(\.theme) var theme
    @Query private var wallets: [Wallet]
    @Query private var categories: [Category]
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    @State private var showingAddWallet = false

    var totalBalance: Double {
        wallets.reduce(0) { $0 + $1.balance }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    totalBalanceCard
                    walletsGrid
                    categoriesSection
                }
                .padding()
            }
            .background(theme.colors.background)
            .navigationTitle("Rekening & Kategori")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddWallet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(theme.colors.primary)
                    }
                }
            }
            .sheet(isPresented: $showingAddWallet) {
                ThemeAddWalletView()
            }
        }
    }

    private var totalBalanceCard: some View {
        ThemedCard {
            VStack(spacing: 8) {
                Text("Total Saldo")
                    .font(theme.fonts.caption)
                    .foregroundStyle(theme.colors.textSecondary)

                Text(totalBalance, format: .currency(code: "IDR"))
                    .font(theme.fonts.largeTitle)
                    .foregroundStyle(theme.colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    private var walletsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(wallets) { wallet in
                ThemedWalletCard(
                    wallet: wallet,
                    isSelected: false,
                    action: {}
                )
            }
        }
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kategori")
                .font(theme.fonts.title)
                .foregroundStyle(theme.colors.textPrimary)

            ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                let spent = calculateSpent(for: category)

                // TODO: Add budget property to Category model or pass 0
                ThemedCategoryCard(
                    category: category,
                    spent: spent,
                    budget: 0
                )
            }
        }
    }

    private func calculateSpent(for category: Category) -> Double {
        transactions
            .filter { $0.category?.id == category.id && $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
}

// MARK: - Theme More View (Settings + Theme Selector)
struct ThemeMoreView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.theme) var theme

    @State private var showingThemeSelector = false

    var body: some View {
        NavigationStack {
            List {
                themeSection
                currentThemeInfo
                previewSection
            }
            .navigationTitle("Pengaturan")
            .sheet(isPresented: $showingThemeSelector) {
                ThemeSelectorView()
            }
        }
    }

    private var themeSection: some View {
        Section("Tampilan") {
            Button(action: { showingThemeSelector = true }) {
                HStack {
                    Image(systemName: "paintbrush.fill")
                        .foregroundStyle(theme.colors.primary)

                    Text("Tema")
                        .foregroundStyle(theme.colors.textPrimary)

                    Spacer()

                    Text(themeManager.selectedTheme.displayName)
                        .font(theme.fonts.caption)
                        .foregroundStyle(theme.colors.textSecondary)

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                }
            }
        }
    }

    private var currentThemeInfo: some View {
        Section("Tema Aktif") {
            HStack {
                Image(systemName: themeManager.selectedTheme.icon)
                    .font(.title2)
                    .foregroundStyle(theme.colors.primary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(themeManager.selectedTheme.displayName)
                        .font(theme.fonts.headline)
                        .foregroundStyle(theme.colors.textPrimary)

                    Text(themeManager.selectedTheme == .copilot
                         ? "UI Modern dengan chart dan trend indicator"
                         : "UI Klasik yang simpel dan bersih")
                        .font(theme.fonts.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var previewSection: some View {
        Section("Preview") {
            VStack(spacing: 12) {
                previewCard
                previewButtons
            }
            .padding(.vertical, 8)
        }
    }

    private var previewCard: some View {
        ThemedCard {
            HStack {
                Image(systemName: "creditcard.fill")
                    .font(.title2)
                    .foregroundStyle(theme.colors.primary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Preview Card")
                        .font(theme.fonts.headline)
                        .foregroundStyle(theme.colors.textPrimary)

                    Text("Ini adalah preview tema")
                        .font(theme.fonts.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                }

                Spacer()

                Text("Rp 1.000.000")
                    .font(theme.fonts.amountSmall)
                    .foregroundStyle(theme.colors.textPrimary)
            }
        }
    }

    private var previewButtons: some View {
        HStack(spacing: 12) {
            Button {} label: {
                Text("Primary")
                    .font(theme.fonts.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(theme.colors.primary)
                    .cornerRadius(12)
            }

            Button {} label: {
                Text("Success")
                    .font(theme.fonts.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(theme.colors.success)
                    .cornerRadius(12)
            }
        }
    }
}

// MARK: - Theme Selector View
struct ThemeSelectorView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(AppTheme.allCases) { theme in
                    themeRow(theme: theme)
                }
            }
            .navigationTitle("Pilih Tema")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
            }
        }
    }

    private func themeRow(theme: AppTheme) -> some View {
        Button(action: {
            themeManager.setTheme(theme)
            dismiss()
        }) {
            HStack(spacing: 16) {
                themeIcon(theme: theme)

                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(theme == .copilot
                         ? "UI Modern dengan chart, shadow, dan trend indicator"
                         : "UI Klasik simpel tanpa shadow")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if themeManager.selectedTheme == theme {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private func themeIcon(theme: AppTheme) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .frame(width: 56, height: 56)

            Image(systemName: theme.icon)
                .font(.system(size: 24))
                .foregroundStyle(theme == .copilot ? Color.green : .blue)
        }
    }
}

// MARK: - Placeholder Views
struct ThemeAddTransactionView: View {
    var body: some View {
        Text("Add Transaction")
    }
}

struct ThemeAddWalletView: View {
    var body: some View {
        Text("Add Wallet")
    }
}
