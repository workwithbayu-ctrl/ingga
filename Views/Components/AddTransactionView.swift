// AddTransactionView.swift
// Views/Transactions/AddTransactionView.swift

import SwiftUI
import SwiftData

enum TransactionTab: String, CaseIterable {
    case income = "Pemasukan"
    case expense = "Pengeluaran"
    case transfer = "Transfer"
}

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var dataService: DataService

    @State private var selectedTab: TransactionTab = .expense
    @State private var amount: String = ""
    @State private var note: String = ""
    @State private var date: Date = Date()
    @State private var selectedCategory: Category?
    @State private var selectedWallet: Wallet?
    @State private var selectedSourceWallet: Wallet?
    @State private var selectedDestWallet: Wallet?
    @State private var showCategoryPicker = false
    @State private var showWalletPicker = false
    @State private var showSourceWalletPicker = false
    @State private var showDestWalletPicker = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var successMessage = ""

    private var currentUser: User? {
        let users = dataService.fetchUsers()
        return users.first
    }

    private var categories: [Category] {
        let type: TransactionType = selectedTab == .income ? .income : .expense
        return dataService.fetchCategories(type: type)
    }

    private var wallets: [Wallet] {
        dataService.fetchWallets()
    }

    private var formattedAmount: String {
        guard let value = Double(amount), value > 0 else { return "Rp 0" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.decimalSeparator = ","
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return "Rp \(formatter.string(from: NSNumber(value: value)) ?? "0")"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0B1220")?.ignoresSafeArea() ?? Color.black.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Tab Selector
                        tabSelector

                        // Amount Display
                        amountDisplay

                        // Form Fields
                        formFields

                        // Save Button
                        saveButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Tambah Transaksi")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Tutup") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "64B4FF"))
                }
            }
            .sheet(isPresented: $showCategoryPicker) {
                CategoryPickerSheet(
                    categories: categories,
                    selectedCategory: $selectedCategory
                )
            }
            .sheet(isPresented: $showWalletPicker) {
                WalletPickerSheetAdd(
                    wallets: wallets,
                    selectedWallet: $selectedWallet,
                    title: "Pilih Dompet"
                )
            }
            .sheet(isPresented: $showSourceWalletPicker) {
                WalletPickerSheetAdd(
                    wallets: wallets,
                    selectedWallet: $selectedSourceWallet,
                    title: "Dari Dompet"
                )
            }
            .sheet(isPresented: $showDestWalletPicker) {
                WalletPickerSheetAdd(
                    wallets: wallets,
                    selectedWallet: $selectedDestWallet,
                    title: "Ke Dompet"
                )
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if showSuccess {
                    SuccessToast(message: successMessage)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { showSuccess = false }
                            }
                        }
                }
            }
        }
        .onAppear {
            if selectedWallet == nil, let first = wallets.first {
                selectedWallet = first
            }
            if selectedSourceWallet == nil, let first = wallets.first {
                selectedSourceWallet = first
            }
            if selectedDestWallet == nil, wallets.count > 1 {
                selectedDestWallet = wallets[1]
            } else if selectedDestWallet == nil, let first = wallets.first {
                selectedDestWallet = first
            }
        }
    }

    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 4) {
            ForEach(TransactionTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                        selectedCategory = nil
                    }
                }) {
                    Text(tab.rawValue)
                        .font(.system(size: 14, weight: selectedTab == tab ? .semibold : .medium))
                        .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedTab == tab ?
                            Color(hex: "64B4FF")?.opacity(0.3) ?? Color.blue.opacity(0.3) :
                            Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Amount Display
    private var amountDisplay: some View {
        VStack(spacing: 8) {
            Text("Jumlah")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))

            Text(formattedAmount)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(
                    selectedTab == .income ? Color.green :
                    selectedTab == .expense ? Color.red : Color(hex: "64B4FF")
                )

            // Number Pad
            NumberPadView(amount: $amount)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "1A2B4A") ?? Color.blue.opacity(0.3),
                    Color(hex: "0B1220") ?? Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Form Fields
    private var formFields: some View {
        VStack(spacing: 16) {
            // Category (for income/expense)
            if selectedTab != .transfer {
                FormFieldButton(
                    icon: "tag.fill",
                    title: "Kategori",
                    value: selectedCategory?.name ?? "Pilih Kategori",
                    color: selectedCategory?.colorHex ?? "64B4FF"
                ) {
                    showCategoryPicker = true
                }
            }

            // Wallet
            if selectedTab == .transfer {
                // Source Wallet
                FormFieldButton(
                    icon: "arrow.up.circle.fill",
                    title: "Dari",
                    value: selectedSourceWallet?.name ?? "Pilih Dompet",
                    color: selectedSourceWallet?.color ?? "64B4FF"
                ) {
                    showSourceWalletPicker = true
                }

                // Dest Wallet
                FormFieldButton(
                    icon: "arrow.down.circle.fill",
                    title: "Ke",
                    value: selectedDestWallet?.name ?? "Pilih Dompet",
                    color: selectedDestWallet?.color ?? "64B4FF"
                ) {
                    showDestWalletPicker = true
                }
            } else {
                FormFieldButton(
                    icon: "wallet.bifold.fill",
                    title: "Dompet",
                    value: selectedWallet?.name ?? "Pilih Dompet",
                    color: selectedWallet?.color ?? "64B4FF"
                ) {
                    showWalletPicker = true
                }
            }

            // Date
            DatePicker(selection: $date, displayedComponents: [.date]) {
                Text("Tanggal")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .datePickerStyle(.compact)
            .padding()
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .colorMultiply(.white)

            // Note
            VStack(alignment: .leading, spacing: 8) {
                Text("Catatan")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))

                TextField("Tambah catatan...", text: $note, axis: .vertical)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "64B4FF")?.opacity(0.3) ?? Color.blue.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }

    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: saveTransaction) {
            HStack {
                Image(systemName: selectedTab == .income ? "arrow.down.circle.fill" :
                                selectedTab == .expense ? "arrow.up.circle.fill" : "arrow.left.arrow.right.circle.fill")
                    .font(.system(size: 20))
                Text("Simpan \(selectedTab.rawValue)")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: "64B4FF") ?? Color.blue,
                        Color(hex: "4A90E2") ?? Color.blue.opacity(0.8)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color(hex: "64B4FF")?.opacity(0.3) ?? Color.blue.opacity(0.3), radius: 15, x: 0, y: 8)
        }
        .disabled(amount.isEmpty || Double(amount) == nil || Double(amount) == 0)
        .opacity(amount.isEmpty || Double(amount) == nil || Double(amount) == 0 ? 0.5 : 1)
    }

    // MARK: - Save Logic
    private func saveTransaction() {
        guard let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "Masukkan jumlah yang valid"
            showError = true
            return
        }

        guard let user = currentUser else {
            errorMessage = "User tidak ditemukan"
            showError = true
            return
        }

        switch selectedTab {
        case .income:
            guard let category = selectedCategory else {
                errorMessage = "Pilih kategori pemasukan"
                showError = true
                return
            }
            guard let wallet = selectedWallet else {
                errorMessage = "Pilih dompet"
                showError = true
                return
            }
            dataService.addIncome(amount: amountValue, note: note, date: date, category: category, wallet: wallet, user: user)
            successMessage = "Pemasukan berhasil ditambahkan"

        case .expense:
            guard let category = selectedCategory else {
                errorMessage = "Pilih kategori pengeluaran"
                showError = true
                return
            }
            guard let wallet = selectedWallet else {
                errorMessage = "Pilih dompet"
                showError = true
                return
            }
            dataService.addExpense(amount: amountValue, note: note, date: date, category: category, wallet: wallet, user: user)
            successMessage = "Pengeluaran berhasil ditambahkan"

        case .transfer:
            guard let source = selectedSourceWallet else {
                errorMessage = "Pilih dompet asal"
                showError = true
                return
            }
            guard let dest = selectedDestWallet else {
                errorMessage = "Pilih dompet tujuan"
                showError = true
                return
            }
            guard source.id != dest.id else {
                errorMessage = "Dompet asal dan tujuan tidak boleh sama"
                showError = true
                return
            }
            dataService.addTransfer(amount: amountValue, note: note, date: date, fromWallet: source, toWallet: dest, user: user)
            successMessage = "Transfer berhasil"
        }

        withAnimation {
            showSuccess = true
        }

        // Reset form
        amount = ""
        note = ""
        selectedCategory = nil

        // Dismiss after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}

// MARK: - Number Pad View
struct NumberPadView: View {
    @Binding var amount: String

    private let buttons: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        [".", "0", "⌫"]
    ]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(buttons, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { button in
                        NumberButton(label: button) {
                            handleInput(button)
                        }
                    }
                }
            }
        }
        .padding(.top, 16)
    }

    private func handleInput(_ input: String) {
        switch input {
        case "⌫":
            if !amount.isEmpty {
                amount.removeLast()
            }
        case ".":
            if !amount.contains(".") {
                amount += "."
            }
        default:
            amount += input
        }
    }
}

struct NumberButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 70, height: 55)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Form Field Button
struct FormFieldButton: View {
    let icon: String
    let title: String
    let value: String
    let color: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: color) ?? Color.blue)
                    .frame(width: 32, height: 32)
                    .background(Color(hex: color)?.opacity(0.15) ?? Color.blue.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))

                    Text(value)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

// MARK: - Category Picker Sheet
struct CategoryPickerSheet: View {
    let categories: [Category]
    @Binding var selectedCategory: Category?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0B1220")?.ignoresSafeArea() ?? Color.black.ignoresSafeArea()

                List {
                    ForEach(categories) { category in
                        Button(action: {
                            selectedCategory = category
                            dismiss()
                        }) {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(hex: category.colorHex)?.opacity(0.2) ?? Color.blue.opacity(0.2))
                                        .frame(width: 40, height: 40)

                                    Image(systemName: category.icon)
                                        .font(.system(size: 18))
                                        .foregroundColor(Color(hex: category.colorHex) ?? Color.blue)
                                }

                                Text(category.name)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)

                                Spacer()

                                if selectedCategory?.id == category.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color(hex: "64B4FF") ?? Color.blue)
                                }
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.05))
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Pilih Kategori")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Tutup") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "64B4FF"))
                }
            }
        }
    }
}

// MARK: - Wallet Picker Sheet (RENAMED to avoid conflict)
struct WalletPickerSheetAdd: View {
    let wallets: [Wallet]
    @Binding var selectedWallet: Wallet?
    let title: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0B1220")?.ignoresSafeArea() ?? Color.black.ignoresSafeArea()

                List {
                    ForEach(wallets) { wallet in
                        Button(action: {
                            selectedWallet = wallet
                            dismiss()
                        }) {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(hex: wallet.color)?.opacity(0.2) ?? Color.blue.opacity(0.2))
                                        .frame(width: 40, height: 40)

                                    Image(systemName: wallet.icon)
                                        .font(.system(size: 18))
                                        .foregroundColor(Color(hex: wallet.color) ?? Color.blue)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(wallet.name)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)

                                    Text("Rp \(formattedBalance(wallet.balance))")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.5))
                                }

                                Spacer()

                                if selectedWallet?.id == wallet.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color(hex: "64B4FF") ?? Color.blue)
                                }
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.05))
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Tutup") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "64B4FF"))
                }
            }
        }
    }

    private func formattedBalance(_ balance: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.decimalSeparator = ","
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: balance)) ?? "0"
    }
}

// MARK: - Success Toast
struct SuccessToast: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.green)

            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            Color(hex: "1A2B4A")?.opacity(0.95) ?? Color.black.opacity(0.9)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        .padding(.top, 60)
    }
}
