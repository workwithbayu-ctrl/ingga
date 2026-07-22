// DashboardView.swift
// Views/Dashboard/DashboardView.swift

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @Query private var wallets: [Wallet]
    @Query(sort: \Pocket.createdAt, order: .reverse) private var pockets: [Pocket]
    @Environment(\.modelContext) private var modelContext

    // MARK: - Swipe State
    @State private var transactionToDelete: Transaction?
    @State private var transactionToEdit: Transaction?
    @State private var showDeleteConfirm = false
    @State private var showEditSheet = false

    // MARK: - Settings Side Menu State
    @State private var showSettings = false
    @State private var settingsDragOffset: CGFloat = 0
    private let settingsMenuWidth: CGFloat = 280
    private let settingsSwipeThreshold: CGFloat = 60

    // MARK: - Navigation State for Settings
    @State private var selectedSettingsDestination: SettingsDestination?

    private var walletBalance: Double {
        wallets.reduce(0) { $0 + $1.balance }
    }

    private var pocketBalance: Double {
        pockets.reduce(0) { $0 + $1.balance }
    }

    private var totalBalance: Double {
        walletBalance + pocketBalance
    }

    private var currentMonthTransactions: [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        return allTransactions.filter { transaction in
            calendar.isDate(transaction.date, equalTo: now, toGranularity: .month)
        }
    }

    private var monthlyIncome: Double {
        currentMonthTransactions
            .filter { $0.type == .income && !$0.isTransfer }
            .reduce(0) { $0 + $1.amount }
    }

    private var monthlyExpense: Double {
        currentMonthTransactions
            .filter { $0.type == .expense && !$0.isTransfer }
            .reduce(0) { $0 + $1.amount }
    }

    private var recentTransactions: [Transaction] {
        Array(allTransactions
            .filter { !$0.isTransfer }
            .prefix(5))
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Background layer - tutupi seluruh screen
                    Color(hex: "0B1220")!
                        .ignoresSafeArea()

                    // Main Dashboard Content
                    mainContent
                        .offset(x: showSettings ? settingsMenuWidth : 0)
                        .offset(x: settingsDragOffset)
                        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.85), value: showSettings)
                        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.85), value: settingsDragOffset)

                    // Settings Side Menu - FIX: zIndex tinggi + contentShape + allowsHitTesting
                    if showSettings || settingsDragOffset > 0 {
                        SettingsSideMenu(
                            isShowing: $showSettings,
                            selectedDestination: $selectedSettingsDestination
                        )
                        .frame(width: settingsMenuWidth, height: geometry.size.height)
                        .offset(x: showSettings ? 0 : -settingsMenuWidth + settingsDragOffset)
                        .offset(x: !showSettings && settingsDragOffset > 0 ? -settingsMenuWidth + settingsDragOffset : 0)
                        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.85), value: showSettings)
                        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.85), value: settingsDragOffset)
                        .zIndex(10) // FIX: zIndex tinggi supaya di atas semua
                        .contentShape(Rectangle()) // FIX: pastikan seluruh area bisa menerima tap
                        .allowsHitTesting(true)
                    }

                    // Overlay to close settings when tapping outside
                    if showSettings {
                        Color.black.opacity(0.01) // FIX: opacity sangat tipis tapi tetap menerima tap
                            .ignoresSafeArea()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .onTapGesture {
                                withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.85)) {
                                    showSettings = false
                                }
                            }
                            .zIndex(5)
                    }
                }
                // FIX: Gesture hanya di area konten (kanan), bukan di area menu (kiri)
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            // Hanya aktif di area kanan (bukan di area menu)
                            let isInMenuArea = value.startLocation.x < settingsMenuWidth && showSettings
                            let isEdgeSwipe = value.startLocation.x < 30 && !showSettings

                            if !showSettings && value.translation.width > 0 && isEdgeSwipe {
                                settingsDragOffset = min(value.translation.width, settingsMenuWidth)
                            } else if showSettings && value.translation.width < 0 && !isInMenuArea {
                                settingsDragOffset = max(value.translation.width, -settingsMenuWidth)
                            }
                        }
                        .onEnded { value in
                            if !showSettings {
                                if value.translation.width > settingsSwipeThreshold {
                                    withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.85)) {
                                        showSettings = true
                                        settingsDragOffset = 0
                                    }
                                } else {
                                    withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.85)) {
                                        settingsDragOffset = 0
                                    }
                                }
                            } else {
                                if value.translation.width < -settingsSwipeThreshold {
                                    withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.85)) {
                                        showSettings = false
                                        settingsDragOffset = 0
                                    }
                                } else {
                                    withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.85)) {
                                        settingsDragOffset = 0
                                    }
                                }
                            }
                        }
                )
            }
            .navigationDestination(item: $selectedSettingsDestination) { destination in
                destinationView(for: destination)
            }
        }
    }

    // MARK: - Main Content
    private var mainContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                topBar

                BalanceCardView(
                    totalBalance: totalBalance,
                    usableBalance: walletBalance,
                    currencyCode: "Rp"
                )

                SpendingChartCardView(
                    monthlyExpense: monthlyExpense,
                    transactions: currentMonthTransactions
                )

                HStack(spacing: 12) {
                    StatCardDark(
                        title: "Pemasukan",
                        amount: monthlyIncome,
                        icon: "arrow.down",
                        iconColor: .green,
                        currencyCode: "Rp"
                    )

                    StatCardDark(
                        title: "Pengeluaran",
                        amount: monthlyExpense,
                        icon: "arrow.up",
                        iconColor: .red,
                        currencyCode: "Rp"
                    )
                }

                PocketSectionCard(pockets: pockets, wallets: wallets)

                RecentTransactionsCard(
                    transactions: recentTransactions,
                    currencyCode: "Rp",
                    transactionToDelete: $transactionToDelete,
                    transactionToEdit: $transactionToEdit,
                    showDeleteConfirm: $showDeleteConfirm,
                    showEditSheet: $showEditSheet
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .background(Color(hex: "0B1220") ?? Color.black)
        .alert("Hapus Transaksi?", isPresented: $showDeleteConfirm) {
            Button("Batal", role: .cancel) { }
            Button("Hapus", role: .destructive) {
                if let t = transactionToDelete {
                    deleteTransaction(t)
                }
            }
        } message: {
            Text("Transaksi ini akan dihapus secara permanen.")
        }
        .sheet(isPresented: $showEditSheet) {
            if let t = transactionToEdit {
                EditTransactionSheet(transaction: t, pockets: pockets, wallets: wallets)
            }
        }
    }

    // MARK: - Destination Views
    @ViewBuilder
    private func destinationView(for destination: SettingsDestination) -> some View {
        switch destination {
        case .profile:
            ProfileView()
        case .notifications:
            NotificationSettingsView()
        case .security:
            SecurityView()
        case .theme:
            ThemeView()
        case .help:
            HelpView()
        case .logout:
            LogoutView()
        }
    }

    private func deleteTransaction(_ transaction: Transaction) {
        if let wallet = transaction.wallet {
            if transaction.type == .income {
                wallet.balance -= transaction.amount
            } else if transaction.type == .expense {
                wallet.balance += transaction.amount
            }
            wallet.updatedAt = Date()
        }
        modelContext.delete(transaction)
        try? modelContext.save()
    }

    private var topBar: some View {
        HStack {
            Spacer()
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text("Selamat Datang")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                Text("Family Budget")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer()

            Menu {
                Button("Suami", action: {})
                Button("Istri", action: {})
            } label: {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: "2C5282") ?? .blue)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text("S")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        )
                    Text("Suami")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Settings Destination Enum
enum SettingsDestination: Hashable {
    case profile
    case notifications
    case security
    case theme
    case help
    case logout
}

// MARK: - Pocket Section Card
struct PocketSectionCard: View {
    let pockets: [Pocket]
    let wallets: [Wallet]
    @State private var showAllPockets = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Pocket Tabungan")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                NavigationLink(destination: PocketListView()) {
                    HStack(spacing: 4) {
                        Text("Lihat Semua")
                            .font(.system(size: 13, weight: .medium))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            if pockets.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 30))
                        .foregroundColor(.white.opacity(0.3))
                    Text("Belum ada pocket")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.vertical, 24)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(pockets.prefix(5)) { pocket in
                            PocketMiniCard(pocket: pocket, wallets: wallets)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color(hex: "2C5282") ?? Color.blue, Color(hex: "0B1220") ?? Color.black],
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
}

struct PocketMiniCard: View {
    let pocket: Pocket
    let wallets: [Wallet]

    var walletName: String {
        if let walletID = pocket.walletID,
           let wallet = wallets.first(where: { $0.id == walletID }) {
            return wallet.name
        }
        return ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color(hex: pocket.colorHex) ?? .blue)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: pocket.icon)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    )
                Spacer()
            }

            Text(pocket.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)

            Text("Rp \(formattedAmount(pocket.balance))")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: pocket.colorHex) ?? .blue)
                        .frame(width: geo.size.width * CGFloat(pocket.progress), height: 4)
                }
            }
            .frame(height: 4)

            Text(pocket.formattedProgress)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(12)
        .frame(width: 140)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
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

// MARK: - Spending Chart Card
struct SpendingChartCardView: View {
    let monthlyExpense: Double
    let transactions: [Transaction]

    @State private var showDetails = false

    private var categoryExpenses: [(category: String, amount: Double, color: Color)] {
        let expenses = transactions.filter { $0.type == .expense && !$0.isTransfer }
        var dict: [String: Double] = [:]
        for t in expenses {
            if let catName = t.category?.name {
                dict[catName, default: 0] += t.amount
            }
        }
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        return dict.sorted { $0.value > $1.value }.enumerated().map { index, item in
            (category: item.key, amount: item.value, color: colors[index % colors.count])
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Pengeluaran Bulan Ini")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text("Juli 2025")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(8)
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showDetails.toggle()
                    }
                }) {
                    Image(systemName: showDetails ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            VStack(spacing: 4) {
                Text("Total Pengeluaran")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("Rp")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                    Text(formattedAmount(monthlyExpense))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                if !showDetails {
                    Text("Tap mata untuk melihat detail")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.top, 4)
                }
            }
            .padding(.vertical, 12)

            if showDetails && !categoryExpenses.isEmpty {
                Divider()
                    .background(Color.white.opacity(0.2))
                    .padding(.horizontal, 20)
                    .transition(.opacity)
                HStack(spacing: 20) {
                    DonutChartView(categories: categoryExpenses)
                        .frame(width: 120, height: 120)
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(0..<min(categoryExpenses.count, 5), id: \.self) { index in
                            let item = categoryExpenses[index]
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 8, height: 8)
                                Text(item.category)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Text("Rp \(formattedAmount(item.amount))")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color(hex: "2C5282") ?? Color.blue, Color(hex: "0B1220") ?? Color.black],
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

// MARK: - Donut Chart
struct DonutChartView: View {
    let categories: [(category: String, amount: Double, color: Color)]

    var body: some View {
        let total = categories.reduce(0) { $0 + $1.amount }
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 20)
            ForEach(0..<categories.count, id: \.self) { index in
                let item = categories[index]
                let percentage = total > 0 ? item.amount / total : 0
                let previousPercentage = index > 0 ?
                    categories[0..<index].reduce(0) { $0 + ($1.amount / total) } : 0
                Circle()
                    .trim(from: 0, to: CGFloat(percentage))
                    .stroke(item.color, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90 + previousPercentage * 360))
            }
        }
    }
}

// MARK: - Stat Card Dark
struct StatCardDark: View {
    let title: String
    let amount: Double
    let icon: String
    let iconColor: Color
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                Spacer()
            }
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            Text("\(currencyCode) \(formattedAmount(amount))")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color(hex: "2C5282") ?? Color.blue, Color(hex: "0B1220") ?? Color.black],
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

// MARK: - Recent Transactions Card
struct RecentTransactionsCard: View {
    let transactions: [Transaction]
    let currencyCode: String

    @Binding var transactionToDelete: Transaction?
    @Binding var transactionToEdit: Transaction?
    @Binding var showDeleteConfirm: Bool
    @Binding var showEditSheet: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Transaksi Terbaru")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                NavigationLink(destination: AllTransactionsView()) {
                    HStack(spacing: 4) {
                        Text("Lihat Semua")
                            .font(.system(size: 13, weight: .medium))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            if transactions.isEmpty {
                Text("Belum ada transaksi")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.vertical, 24)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(transactions.enumerated()), id: \.element.id) { index, transaction in
                        SwipeableTransactionRow(
                            transaction: transaction,
                            currencyCode: currencyCode,
                            onDelete: {
                                transactionToDelete = transaction
                                showDeleteConfirm = true
                            },
                            onEdit: {
                                transactionToEdit = transaction
                                showEditSheet = true
                            }
                        )
                        if index < transactions.count - 1 {
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.leading, 72)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color(hex: "2C5282") ?? Color.blue, Color(hex: "0B1220") ?? Color.black],
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
}

// MARK: - Swipeable Transaction Row (Seamless / Hidden Buttons)
struct SwipeableTransactionRow: View {
    let transaction: Transaction
    let currencyCode: String
    let onDelete: () -> Void
    let onEdit: () -> Void

    @State private var offset: CGFloat = 0
    private let swipeThreshold: CGFloat = 60
    private let actionWidth: CGFloat = 80

    private var iconEmoji: String {
        guard let icon = transaction.category?.icon else { return "📋" }
        let map: [String: String] = [
            "dollarsign.circle.fill": "💰",
            "person.fill": "👤",
            "person.2.fill": "👥",
            "banknote.fill": "💵",
            "building.columns.fill": "🏛️",
            "cart.fill": "🛒",
            "car.fill": "🚗",
            "house.fill": "🏠",
            "fork.knife": "🍽️",
            "bolt.fill": "⚡",
            "heart.fill": "❤️",
            "gamecontroller.fill": "🎮",
            "airplane": "✈️",
            "bag.fill": "🛍️",
            "pills.fill": "💊",
            "tv.fill": "📺",
            "wifi": "📶",
            "phone.fill": "📞",
            "envelope.fill": "✉️",
            "gift.fill": "🎁",
            "creditcard.fill": "💳",
            "star.fill": "⭐",
            "briefcase.fill": "💼",
            "laptopcomputer": "💻",
            "chart.line.uptrend.xyaxis": "📈",
            "ellipsis.circle.fill": "⋯",
            "arrow.left.arrow.right": "↔️",
            "doc.text": "📝"
        ]
        return map[icon] ?? "📋"
    }

    private var displayNote: String {
        if !transaction.note.isEmpty {
            return transaction.note
        }
        return transaction.category?.name ?? "Transaksi"
    }

    private var categoryName: String {
        transaction.category?.name ?? ""
    }

    private var categoryIcon: String {
        transaction.category?.icon ?? "doc.text"
    }

    var body: some View {
        ZStack {
            // Background color layer — seamless, no buttons visible
            HStack(spacing: 0) {
                // LEFT side — EDIT (blue) reveals as you swipe right
                ZStack {
                    Color.blue.opacity(0.9)

                    Image(systemName: "pencil")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .opacity(offset > 20 ? 1 : 0)
                        .scaleEffect(offset > 40 ? 1 : 0.5)
                }
                .frame(width: offset > 0 ? min(offset, actionWidth) : 0)
                .opacity(offset > 0 ? 1 : 0)

                Spacer()

                // RIGHT side — DELETE (red) reveals as you swipe left
                ZStack {
                    Color.red.opacity(0.9)

                    Image(systemName: "trash.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .opacity(offset < -20 ? 1 : 0)
                        .scaleEffect(offset < -40 ? 1 : 0.5)
                }
                .frame(width: offset < 0 ? min(abs(offset), actionWidth) : 0)
                .opacity(offset < 0 ? 1 : 0)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Foreground row content — solid background to hide actions behind
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 44, height: 44)
                    if UIImage(systemName: categoryIcon) != nil {
                        Image(systemName: categoryIcon)
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.8))
                    } else {
                        Text(iconEmoji)
                            .font(.system(size: 20))
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(displayNote)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    if !categoryName.isEmpty {
                        Text(categoryName)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                Spacer()

                Text("\(currencyCode) \(formattedAmount(transaction.amount))")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(transaction.type == .income ? .green : .red)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [Color(hex: "2C5282") ?? Color.blue, Color(hex: "0B1220") ?? Color.black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .offset(x: offset)
            .highPriorityGesture(
                DragGesture(minimumDistance: 15)
                    .onChanged { value in
                        let width = value.translation.width
                        if width > 0 {
                            offset = min(width, actionWidth)
                        } else {
                            offset = max(width, -actionWidth)
                        }
                    }
                    .onEnded { value in
                        let width = value.translation.width
                        let velocity = value.predictedEndLocation.x - value.location.x

                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            if width > swipeThreshold || velocity > 100 {
                                offset = actionWidth
                            } else if width < -swipeThreshold || velocity < -100 {
                                offset = -actionWidth
                            } else {
                                offset = 0
                            }
                        }

                        // Auto-trigger after snap animation
                        if offset == actionWidth {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                withAnimation(.spring()) { offset = 0 }
                                onEdit()
                            }
                        } else if offset == -actionWidth {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                withAnimation(.spring()) { offset = 0 }
                                onDelete()
                            }
                        }
                    }
            )
        }
        .frame(height: 70)
        .clipShape(RoundedRectangle(cornerRadius: 12))
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

// MARK: - Settings Side Menu (FIX: pakai Button + navigationDestination)
struct SettingsSideMenu: View {
    @Binding var isShowing: Bool
    @Binding var selectedDestination: SettingsDestination?

    var body: some View {
        ZStack {
            Color(hex: "161F30")!
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Pengaturan")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.85)) {
                            isShowing = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 20)

                // Menu Items - FIX: pakai Button yang set selectedDestination
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 8) {
                        SettingsMenuButton(icon: "person.fill", title: "Profil", color: "64B4FF") {
                            isShowing = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                selectedDestination = .profile
                            }
                        }
                        SettingsMenuButton(icon: "bell.fill", title: "Notifikasi", color: "FF9500") {
                            isShowing = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                selectedDestination = .notifications
                            }
                        }
                        SettingsMenuButton(icon: "lock.fill", title: "Keamanan", color: "34C759") {
                            isShowing = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                selectedDestination = .security
                            }
                        }
                        SettingsMenuButton(icon: "paintbrush.fill", title: "Tema", color: "AF52DE") {
                            isShowing = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                selectedDestination = .theme
                            }
                        }
                        SettingsMenuButton(icon: "questionmark.circle.fill", title: "Bantuan", color: "5AC8FA") {
                            isShowing = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                selectedDestination = .help
                            }
                        }

                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.vertical, 8)

                        SettingsMenuButton(icon: "arrow.right.square.fill", title: "Keluar", color: "FF3B30") {
                            isShowing = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                selectedDestination = .logout
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                Spacer()

                Text("FamilyBudgetPro v1.0")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.bottom, 30)
            }
        }
    }
}

// MARK: - Settings Menu Button (FIX: pakai Button biasa, bukan NavigationLink)
struct SettingsMenuButton: View {
    let icon: String
    let title: String
    let color: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: color)!.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: color)!)
                }

                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Edit Transaction Sheet
struct EditTransactionSheet: View {
    let transaction: Transaction
    let pockets: [Pocket]
    let wallets: [Wallet]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var amount: String = ""
    @State private var note: String = ""
    @State private var date: Date = Date()
    @State private var selectedPocket: Pocket?
    @State private var allocateToPocket: Bool = false

    init(transaction: Transaction, pockets: [Pocket], wallets: [Wallet]) {
        self.transaction = transaction
        self.pockets = pockets
        self.wallets = wallets
        _amount = State(initialValue: String(format: "%.0f", transaction.amount))
        _note = State(initialValue: transaction.note)
        _date = State(initialValue: transaction.date)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "1A1A2E")?.ignoresSafeArea() ?? Color.black.ignoresSafeArea()

                Form {
                    Section("Jumlah") {
                        TextField("Rp", text: $amount)
                            .keyboardType(.numberPad)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    Section("Catatan") {
                        TextField("Catatan", text: $note)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    Section("Tanggal") {
                        DatePicker("", selection: $date)
                            .datePickerStyle(.compact)
                            .colorMultiply(.blue)
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    if transaction.type == .income && !pockets.isEmpty {
                        Section("Alokasi ke Pocket") {
                            Toggle("Alokasi otomatis", isOn: $allocateToPocket)
                                .foregroundColor(.white)

                            if allocateToPocket {
                                Picker("Pilih Pocket", selection: $selectedPocket) {
                                    Text("Tidak ada").tag(nil as Pocket?)
                                    ForEach(pockets) { pocket in
                                        let walletName = wallets.first(where: { $0.id == pocket.walletID })?.name ?? ""
                                        Text("\(pocket.name) (\(walletName))")
                                            .tag(pocket as Pocket?)
                                    }
                                }
                                .foregroundColor(.white)
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.05))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Edit Transaksi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan") {
                        saveChanges()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }

    private func saveChanges() {
        let oldAmount = transaction.amount
        if let newAmount = Double(amount), let wallet = transaction.wallet {
            let diff = newAmount - oldAmount
            if transaction.type == .income {
                wallet.balance += diff
            } else if transaction.type == .expense {
                wallet.balance -= diff
            }
            wallet.updatedAt = Date()
            transaction.amount = newAmount
        }
        transaction.note = note
        transaction.date = date

        if allocateToPocket, let pocket = selectedPocket, transaction.type == .income {
            let allocationAmount = transaction.amount * (pocket.allocationPercentage / 100)
            if let wallet = wallets.first(where: { $0.id == pocket.walletID }) {
                if wallet.balance >= allocationAmount {
                    wallet.balance -= allocationAmount
                    wallet.updatedAt = Date()
                    pocket.balance += allocationAmount
                }
            }
        }

        try? modelContext.save()
        dismiss()
    }
}
