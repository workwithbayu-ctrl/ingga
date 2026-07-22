import SwiftUI
import SwiftData

struct PocketDepositView: View {
    @Environment(\.dismiss) private var dismiss
    let pocket: Pocket

    @State private var amount: String = ""
    @State private var note: String = ""
    @State private var selectedWallet: Wallet?
    @State private var selectedDate: Date = Date()

    var wallets: [Wallet] {
        DataService.shared.fetchWallets()
    }

    var isValid: Bool {
        let amountValue = Double(amount) ?? 0
        return amountValue > 0 && selectedWallet != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Dark background
                Color(hex: "0B1220")?.ignoresSafeArea() ?? Color.black.ignoresSafeArea()

                Form {
                    // MARK: - Amount Section
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Jumlah Setor")
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
                                    .foregroundColor(.green)
                            }

                            if let wallet = selectedWallet {
                                Text("Saldo \(wallet.name): \(wallet.balance.formattedCurrency())")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    // MARK: - Source Wallet
                    Section("Dari Dompet") {
                        if wallets.isEmpty {
                            Text("Belum ada dompet")
                                .foregroundColor(.white.opacity(0.5))
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(wallets) { wallet in
                                        DepositWalletButtonDark(
                                            wallet: wallet,
                                            isSelected: selectedWallet?.id == wallet.id
                                        ) {
                                            selectedWallet = wallet
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    // MARK: - Destination Pocket
                    Section("Ke Pocket") {
                        HStack {
                            Image(systemName: pocket.icon)
                                .foregroundStyle(Color(hex: pocket.colorHex) ?? .gray)
                            Text(pocket.name)
                                .foregroundColor(.white)
                            Spacer()
                            Text(pocket.balance.formattedCurrency())
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.05))

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
            .navigationTitle("Setor ke \(pocket.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "0B1220") ?? Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                        .foregroundColor(.white)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Setor") {
                        performDeposit()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                    .foregroundColor(isValid ? .green : .white.opacity(0.3))
                }
            }
            .onAppear {
                selectedWallet = wallets.first
            }
        }
        .tint(.white)
    }

    private func performDeposit() {
        guard let wallet = selectedWallet,
              let amountValue = Double(amount) else {
            return
        }

        DataService.shared.depositToPocket(
            pocket: pocket,
            amount: amountValue,
            from: wallet,
            note: note,
            date: selectedDate
        )

        dismiss()
    }
}

// MARK: - Deposit Wallet Button Dark
struct DepositWalletButtonDark: View {
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
