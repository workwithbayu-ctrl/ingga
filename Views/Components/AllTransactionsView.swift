// AllTransactionsView.swift
// Views/Transactions/AllTransactionsView.swift

import SwiftUI
import SwiftData

enum PeriodFilter: String, CaseIterable {
    case daily = "Harian"
    case monthly = "Bulanan"
    case yearly = "Tahunan"
}

enum TypeFilter: String, CaseIterable {
    case all = "Semua"
    case income = "Pemasukan"
    case expense = "Pengeluaran"
}

struct AllTransactionsView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @Query private var wallets: [Wallet]
    @Query(sort: \Pocket.createdAt, order: .reverse) private var pockets: [Pocket]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var dataService: DataService

    @State private var selectedPeriod: PeriodFilter = .monthly
    @State private var selectedType: TypeFilter = .all
    @State private var currentDate = Date()
    @State private var showDatePicker = false

    // MARK: - Swipe State
    @State private var transactionToDelete: Transaction?
    @State private var transactionToEdit: Transaction?
    @State private var showDeleteConfirm = false
    @State private var showEditSheet = false

    private var filteredTransactions: [Transaction] {
        let calendar = Calendar.current
        var filtered = allTransactions

        switch selectedPeriod {
        case .daily:
            filtered = filtered.filter { calendar.isDate($0.date, inSameDayAs: currentDate) }
        case .monthly:
            filtered = filtered.filter {
                calendar.isDate($0.date, equalTo: currentDate, toGranularity: .month)
            }
        case .yearly:
            filtered = filtered.filter {
                calendar.isDate($0.date, equalTo: currentDate, toGranularity: .year)
            }
        }

        switch selectedType {
        case .income:
            filtered = filtered.filter { $0.type == .income }
        case .expense:
            filtered = filtered.filter { $0.type == .expense }
        case .all:
            break
        }

        return filtered
    }

    private var totalIncome: Double {
        filteredTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    private var totalExpense: Double {
        filteredTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    private var periodTitle: String {
        let formatter = DateFormatter()
        switch selectedPeriod {
        case .daily:
            formatter.dateFormat = "d MMM yyyy"
        case .monthly:
            formatter.dateFormat = "MMMM yyyy"
        case .yearly:
            formatter.dateFormat = "yyyy"
        }
        return formatter.string(from: currentDate)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                FilterChipsCard(
                    selectedPeriod: $selectedPeriod,
                    selectedType: $selectedType
                )

                DateNavigationCard(
                    periodTitle: periodTitle,
                    onPrevious: previousPeriod,
                    onNext: nextPeriod
                )

                SummaryCard(income: totalIncome, expense: totalExpense)

                TransactionListCard(
                    transactions: filteredTransactions,
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
        .navigationTitle("Transaksi")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheetDark(selectedDate: $currentDate, isPresented: $showDatePicker)
        }
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

    // FIX: Use DataService to delete transaction (same context)
    private func deleteTransaction(_ transaction: Transaction) {
        dataService.deleteTransaction(transaction)
    }

    private func previousPeriod() {
        let calendar = Calendar.current
        switch selectedPeriod {
        case .daily:
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        case .monthly:
            currentDate = calendar.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
        case .yearly:
            currentDate = calendar.date(byAdding: .year, value: -1, to: currentDate) ?? currentDate
        }
    }

    private func nextPeriod() {
        let calendar = Calendar.current
        switch selectedPeriod {
        case .daily:
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        case .monthly:
            currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
        case .yearly:
            currentDate = calendar.date(byAdding: .year, value: 1, to: currentDate) ?? currentDate
        }
    }
}

// MARK: - Filter Chips Card
struct FilterChipsCard: View {
    @Binding var selectedPeriod: PeriodFilter
    @Binding var selectedType: TypeFilter

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(PeriodFilter.allCases, id: \.self) { period in
                    FilterChipDark(
                        title: period.rawValue,
                        isSelected: selectedPeriod == period
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedPeriod = period
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                ForEach(TypeFilter.allCases, id: \.self) { type in
                    FilterChipDark(
                        title: type.rawValue,
                        isSelected: selectedType == type
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedType = type
                        }
                    }
                }
            }
        }
        .padding(16)
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
}

// MARK: - Date Navigation Card
struct DateNavigationCard: View {
    let periodTitle: String
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }

            Spacer()

            Text(periodTitle)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
}

// MARK: - Summary Card
struct SummaryCard: View {
    let income: Double
    let expense: Double

    var body: some View {
        HStack(spacing: 0) {
            SummaryItemDark(title: "Pemasukan", amount: income, color: .green)

            Divider()
                .background(Color.white.opacity(0.2))

            SummaryItemDark(title: "Pengeluaran", amount: expense, color: .red)

            Divider()
                .background(Color.white.opacity(0.2))

            SummaryItemDark(title: "Sisa", amount: income - expense, color: .white)
        }
        .padding(.vertical, 16)
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
}

// MARK: - Transaction List Card
struct TransactionListCard: View {
    let transactions: [Transaction]
    let currencyCode: String

    @Binding var transactionToDelete: Transaction?
    @Binding var transactionToEdit: Transaction?
    @Binding var showDeleteConfirm: Bool
    @Binding var showEditSheet: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Daftar Transaksi")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Text("\(transactions.count) transaksi")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            if transactions.isEmpty {
                Text("Tidak ada transaksi")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 32)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(transactions.enumerated()), id: \.element.id) { index, transaction in
                        SwipeableTransactionRowAll(
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
}

// MARK: - Swipeable Transaction Row (Seamless / Hidden Buttons)
struct SwipeableTransactionRowAll: View {
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

    // ✅ FIX: Handle transfer color
    private var transactionColor: Color {
        switch transaction.type {
        case .income:
            return .green
        case .expense:
            return .red
        case .transfer:
            return Color(hex: "64B4FF") ?? .blue
        }
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

                // ✅ FIX: Use transactionColor for amount
                Text("\(currencyCode) \(formattedAmount(transaction.amount))")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(transactionColor)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            // FIX: Solid background matching the card gradient
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
                            // Snap to action if swiped far enough or with velocity
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

struct FilterChipDark: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.white.opacity(0.25) : Color.white.opacity(0.1))
                .cornerRadius(20)
        }
    }
}

struct SummaryItemDark: View {
    let title: String
    let amount: Double
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.7))

            Text("Rp \(formattedAmount(amount))")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
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

struct DatePickerSheetDark: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "1A1A2E")?.ignoresSafeArea() ?? Color.black.ignoresSafeArea()

                VStack {
                    DatePicker(
                        "Pilih Tanggal",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .colorMultiply(.white)
                    .padding()

                    Spacer()
                }
            }
            .navigationTitle("Pilih Tanggal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Selesai") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}
