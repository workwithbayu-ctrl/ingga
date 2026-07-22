// WalletListView.swift
// Views/Wallets/WalletListView.swift

import SwiftUI
import SwiftData

struct WalletListView: View {
    @Query(sort: \Wallet.sortOrder) private var wallets: [Wallet]
    @Environment(\.modelContext) private var modelContext

    @State private var showingAddWallet = false
    @State private var editingWallet: Wallet? = nil
    @State private var showingDeleteAlert = false
    @State private var walletToDelete: Wallet? = nil

    private var totalBalance: Double {
        wallets.reduce(0) { $0 + $1.balance }
    }

    var body: some View {
        ZStack {
            Color(hex: "0B1220")!
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Wallet")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    Button {
                        showingAddWallet = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "2C5282")!)
                                .frame(width: 36, height: 36)
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Total Saldo
                VStack(spacing: 4) {
                    Text("Total Saldo")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))

                    Text("Rp \(formattedAmount(totalBalance))")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.vertical, 16)

                // Wallet List
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(wallets) { wallet in
                            walletCard(wallet)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showingAddWallet) {
            WalletFormSheet(mode: .add)
        }
        .sheet(item: $editingWallet) { wallet in
            WalletFormSheet(mode: .edit(wallet))
        }
        .alert("Hapus Wallet?", isPresented: $showingDeleteAlert) {
            Button("Batal", role: .cancel) {}
            Button("Hapus", role: .destructive) {
                if let wallet = walletToDelete {
                    deleteWallet(wallet)
                }
            }
        } message: {
            if let wallet = walletToDelete {
                Text("Wallet '\(wallet.name)' akan dihapus. Transaksi terkait tidak akan terhapus.")
            }
        }
    }

    private func walletCard(_ wallet: Wallet) -> some View {
        HStack(spacing: 14) {
            // Bank Icon
            ZStack {
                Circle()
                    .fill(Color(hex: wallet.colorHex) ?? Color.blue)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )

                Text(walletIconText(for: wallet))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(wallet.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                if let bankName = wallet.bankDisplayName {
                    Text(bankName)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }

                if let holder = wallet.accountHolder, !holder.isEmpty {
                    Text(holder)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.35))
                }
            }

            Spacer()

            // Balance
            Text("Rp \(formattedAmount(wallet.balance))")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            editingWallet = wallet
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                walletToDelete = wallet
                showingDeleteAlert = true
            } label: {
                Label("Hapus", systemImage: "trash")
            }
        }
    }

    private func walletIconText(for wallet: Wallet) -> String {
        guard let code = wallet.bankCode?.uppercased() else {
            return wallet.walletType == .cash ? "💵" : String(wallet.name.prefix(1)).uppercased()
        }

        if code.contains("BCA") { return "B" }
        if code.contains("MANDIRI") { return "M" }
        if code.contains("BNI") { return "N" }
        if code.contains("BRI") { return "R" }
        if code.contains("BSI") || code.contains("SYARIAH") { return "S" }
        if code.contains("CIMB") { return "C" }
        if code.contains("DANAMON") { return "D" }
        if code.contains("PERMATA") { return "P" }
        if code.contains("PANIN") { return "Pn" }
        if code.contains("MAYBANK") { return "My" }
        if code.contains("MEGA") { return "Mg" }
        if code.contains("BTPN") || code.contains("JENIUS") { return "J" }
        if code.contains("BLU") { return "Bl" }
        if code.contains("LIVIN") || code.contains("MANDIRI") { return "L" }
        if code.contains("BRIMO") { return "Br" }
        if code.contains("NEO") { return "N" }
        if code.contains("SEABANK") { return "Sb" }
        if code.contains("JAGO") { return "Jg" }
        if code.contains("ALLO") { return "A" }
        return String(code.prefix(1))
    }

    private func deleteWallet(_ wallet: Wallet) {
        modelContext.delete(wallet)
        try? modelContext.save()
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

// MARK: - Wallet Form Sheet (Add/Edit combined)
enum WalletFormMode {
    case add
    case edit(Wallet)
}

struct WalletFormSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let mode: WalletFormMode

    @State private var name = ""
    @State private var selectedBank: IndonesianBank = .bca
    @State private var selectedColorHex = "#003399"
    @State private var accountHolder = ""
    @State private var accountNumber = ""
    @State private var balance = ""
    @State private var walletType: WalletType = .bank

    var isEdit: Bool {
        if case .edit = mode { return true }
        return false
    }

    init(mode: WalletFormMode) {
        self.mode = mode
        if case .edit(let wallet) = mode {
            _name = State(initialValue: wallet.name)
            if let code = wallet.bankCode,
               let bank = IndonesianBank.allCases.first(where: { $0.code == code }) {
                _selectedBank = State(initialValue: bank)
                _selectedColorHex = State(initialValue: bankColorHex(for: bank))
            }
            _accountHolder = State(initialValue: wallet.accountHolder ?? "")
            _accountNumber = State(initialValue: wallet.accountNumber ?? "")
            _balance = State(initialValue: String(format: "%.0f", wallet.balance))
            _walletType = State(initialValue: wallet.walletType)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0B1220")!
                    .ignoresSafeArea()

                Form {
                    // Tipe Wallet Section
                    Section {
                        Picker("Tipe", selection: $walletType) {
                            ForEach(WalletType.allCases, id: \.self) { type in
                                Text(type.displayName)
                                    .foregroundColor(.white)
                                    .tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .colorMultiply(Color(hex: "64B4FF")!)
                    } header: {
                        Text("Tipe Wallet")
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .listRowBackground(Color.white.opacity(0.08))

                    // Informasi Section
                    Section {
                        // Nama Wallet
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Nama Wallet")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                            TextField("Contoh: BCA Utama", text: $name)
                                .foregroundColor(.white)
                                .tint(Color(hex: "64B4FF")!)
                        }
                        .padding(.vertical, 4)

                        if walletType != .cash {
                            // Bank Picker
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Bank")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.5))
                                Picker("", selection: $selectedBank) {
                                    ForEach(IndonesianBank.allCases, id: \.self) { bank in
                                        Text(bank.name)
                                            .foregroundColor(.white)
                                            .tag(bank)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.white)
                            }
                            .padding(.vertical, 4)
                            .onChange(of: selectedBank) { _, newBank in
                                selectedColorHex = bankColorHex(for: newBank)
                            }

                            // Nama Pemilik
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Nama Pemilik")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.5))
                                TextField("Contoh: John Doe", text: $accountHolder)
                                    .foregroundColor(.white)
                                    .tint(Color(hex: "64B4FF")!)
                            }
                            .padding(.vertical, 4)

                            // Nomor Rekening
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Nomor Rekening")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.5))
                                TextField("Contoh: 1234567890", text: $accountNumber)
                                    .foregroundColor(.white)
                                    .tint(Color(hex: "64B4FF")!)
                                    .keyboardType(.numberPad)
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Text("Informasi")
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .listRowBackground(Color.white.opacity(0.08))

                    // Saldo Section
                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Saldo Awal")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                            TextField("0", text: $balance)
                                .foregroundColor(.white)
                                .tint(Color(hex: "64B4FF")!)
                                .keyboardType(.numberPad)
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("Saldo")
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .listRowBackground(Color.white.opacity(0.08))
                }
                .scrollContentBackground(.hidden)
                .background(Color(hex: "0B1220")!)
            }
            .navigationTitle(isEdit ? "Edit Wallet" : "Wallet Baru")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan") {
                        saveWallet()
                    }
                    .foregroundColor(Color(hex: "64B4FF")!)
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveWallet() {
        let newColorHex = walletType == .cash ? "#34C759" : selectedColorHex

        if case .edit(let wallet) = mode {
            wallet.name = name
            wallet.walletType = walletType
            wallet.bankCode = walletType == .cash ? nil : selectedBank.code
            wallet.accountHolder = accountHolder.isEmpty ? nil : accountHolder
            wallet.accountNumber = accountNumber.isEmpty ? nil : accountNumber
            wallet.balance = Double(balance) ?? 0
            wallet.colorHex = newColorHex
            wallet.icon = walletType.icon
            wallet.updatedAt = Date()
            try? modelContext.save()
        } else {
            let maxSort = (try? modelContext.fetch(FetchDescriptor<Wallet>()).map(\.sortOrder).max()) ?? 0

            let wallet = Wallet(
                name: name,
                type: walletType,
                bankCode: walletType == .cash ? nil : selectedBank.code,
                accountNumber: accountNumber.isEmpty ? nil : accountNumber,
                balance: Double(balance) ?? 0,
                icon: walletType.icon,
                colorHex: newColorHex,
                accountHolder: accountHolder.isEmpty ? nil : accountHolder,
                sortOrder: maxSort + 1
            )
            modelContext.insert(wallet)
            try? modelContext.save()
        }
        dismiss()
    }

    // MARK: - Bank Color Helper (pakai bank.code, bukan case name)
    private func bankColorHex(for bank: IndonesianBank) -> String {
        let code = bank.code.uppercased()
        if code.contains("BCA") { return "#003399" }
        if code.contains("MANDIRI") { return "#FFD700" }
        if code.contains("BNI") { return "#FF6600" }
        if code.contains("BRI") { return "#0055A4" }
        if code.contains("BSI") || code.contains("SYARIAH") { return "#009639" }
        if code.contains("CIMB") { return "#EC1C24" }
        if code.contains("DANAMON") { return "#E31837" }
        if code.contains("PERMATA") { return "#C8102E" }
        if code.contains("PANIN") { return "#0047AB" }
        if code.contains("MAYBANK") { return "#FFD100" }
        if code.contains("MEGA") { return "#E31837" }
        if code.contains("BTPN") || code.contains("JENIUS") { return "#00A4E4" }
        if code.contains("BLU") { return "#00B4D8" }
        if code.contains("LIVIN") { return "#0055A4" }
        if code.contains("BRIMO") { return "#0055A4" }
        if code.contains("NEO") { return "#FF6B00" }
        if code.contains("SEABANK") { return "#00A4E4" }
        if code.contains("JAGO") { return "#FF6B00" }
        if code.contains("ALLO") { return "#E31837" }
        return "#2C5282"
    }
}
