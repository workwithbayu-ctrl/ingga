import SwiftUI
import SwiftData

struct TransferView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataService = DataService.shared

    @State private var amount: String = ""
    @State private var note: String = ""
    @State private var selectedSourceWallet: Wallet?
    @State private var selectedDestinationWallet: Wallet?
    @State private var selectedDate: Date = Date()
    @State private var showInsufficientAlert = false

    var wallets: [Wallet] {
        dataService.fetchWallets()
    }

    var destinationWallets: [Wallet] {
        guard let source = selectedSourceWallet else { return [] }
        return wallets.filter { $0.id != source.id }
    }

    var latestSourceBalance: Double {
        guard let source = selectedSourceWallet else { return 0 }
        let latestWallets = dataService.fetchWallets()
        return latestWallets.first(where: { $0.id == source.id })?.balance ?? 0
    }

    var isValid: Bool {
        let amountValue = Double(amount) ?? 0
        guard let source = selectedSourceWallet else { return false }
        let latestWallets = dataService.fetchWallets()
        guard let latestSource = latestWallets.first(where: { $0.id == source.id }) else { return false }
        return amountValue > 0
            && amountValue <= latestSource.balance
            && selectedDestinationWallet != nil
            && source.id != selectedDestinationWallet?.id
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0B1220")?.ignoresSafeArea() ?? Color.black.ignoresSafeArea()

                Form {
                    // MARK: - Amount Section
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Jumlah Transfer")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))

                            HStack {
                                Text("Rp")
                                    .font(.title)
                                    .foregroundColor(.white.opacity(0.6))

                                TextField("0", text: $amount)
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .foregroundColor(.blue)
                            }

                            if let source = selectedSourceWallet {
                                HStack {
                                    Text("Saldo \(source.name):")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.5))
                                    Text(latestSourceBalance.formattedCurrency())
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(latestSourceBalance >= (Double(amount) ?? 0) ? .green : .red)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    // MARK: - Source Wallet
                    Section("Dari Rekening") {
                        if wallets.isEmpty {
                            Text("Belum ada rekening")
                                .foregroundColor(.white.opacity(0.5))
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(wallets) { wallet in
                                        TransferWalletButtonDark(
                                            wallet: wallet,
                                            isSelected: selectedSourceWallet?.id == wallet.id
                                        ) {
                                            selectedSourceWallet = wallet
                                            selectedDestinationWallet = nil
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    // MARK: - Destination Wallet
                    Section("Ke Rekening") {
                        if selectedSourceWallet == nil {
                            Text("Pilih rekening sumber terlebih dahulu")
                                .foregroundColor(.white.opacity(0.5))
                        } else if destinationWallets.isEmpty {
                            Text("Tidak ada rekening lain")
                                .foregroundColor(.white.opacity(0.5))
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(destinationWallets) { wallet in
                                        TransferWalletButtonDark(
                                            wallet: wallet,
                                            isSelected: selectedDestinationWallet?.id == wallet.id
                                        ) {
                                            selectedDestinationWallet = wallet
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    // MARK: - Transfer Summary
                    if let source = selectedSourceWallet,
                       let dest = selectedDestinationWallet,
                       let amountValue = Double(amount),
                       amountValue > 0 {
                        Section("Ringkasan") {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Dari")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.5))
                                        HStack {
                                            Image(systemName: source.icon)
                                                .foregroundColor(Color(hex: source.colorHex) ?? .gray)
                                            Text(source.name)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "arrow.right")
                                        .foregroundColor(.white.opacity(0.5))

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("Ke")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.5))
                                        HStack {
                                            Text(dest.name)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                            Image(systemName: dest.icon)
                                                .foregroundColor(Color(hex: dest.colorHex) ?? .gray)
                                        }
                                    }
                                }

                                Divider()
                                    .background(Color.white.opacity(0.1))

                                HStack {
                                    Text("Jumlah")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(amountValue.formattedCurrency())
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                }

                                if amountValue > latestSourceBalance {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                        Text("Saldo tidak cukup! Tersedia: \(latestSourceBalance.formattedCurrency())")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.white.opacity(0.05))
                    }

                    // MARK: - Detail
                    Section("Detail") {
                        TextField("Catatan (opsional)", text: $note)
                            .foregroundColor(.white)
                        DatePicker("Tanggal", selection: $selectedDate, displayedComponents: [.date])
                            .colorMultiply(.white)
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Transfer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "0B1220") ?? Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                        .foregroundColor(.white)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Transfer") {
                        performTransfer()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                    .foregroundColor(isValid ? .blue : .white.opacity(0.3))
                }
            }
            .alert("Saldo Tidak Cukup", isPresented: $showInsufficientAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Saldo tersedia: \(latestSourceBalance.formattedCurrency())")
            }
            .onAppear {
                if selectedSourceWallet == nil, let firstWallet = wallets.first {
                    selectedSourceWallet = firstWallet
                }
            }
        }
        .tint(.white)
    }

    private func performTransfer() {
        guard let source = selectedSourceWallet,
              let destination = selectedDestinationWallet,
              let amountValue = Double(amount),
              amountValue > 0 else {
            return
        }

        let latestWallets = dataService.fetchWallets()
        guard let latestSource = latestWallets.first(where: { $0.id == source.id }),
              latestSource.balance >= amountValue else {
            showInsufficientAlert = true
            return
        }

        let users = dataService.fetchUsers()
        let currentUser = users.first ?? User(name: "User", email: "", password: "", role: .husband, colorHex: "#007AFF")

        dataService.addTransfer(
            amount: amountValue,
            note: note,
            date: selectedDate,
            fromWallet: source,
            toWallet: destination,
            user: currentUser
        )

        dismiss()
    }
}

// MARK: - Transfer Wallet Button Dark
struct TransferWalletButtonDark: View {
    let wallet: Wallet
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(hex: wallet.colorHex)?.opacity(isSelected ? 0.25 : 0.1) ?? Color.gray.opacity(0.1))
                        .frame(width: 56, height: 56)

                    Image(systemName: wallet.icon)
                        .font(.title3)
                        .foregroundColor(Color(hex: wallet.colorHex) ?? .gray)
                }
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color(hex: wallet.colorHex) ?? .blue : Color.clear, lineWidth: 3)
                )

                Text(wallet.name)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 70)

                Text(wallet.balance.formattedCurrency())
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 80)
            }
        }
        .buttonStyle(.plain)
    }
}
