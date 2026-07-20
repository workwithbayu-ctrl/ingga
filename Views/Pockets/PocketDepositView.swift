import SwiftUI
import SwiftData

struct PocketDepositView: View {
    @Environment(\.dismiss) private var dismiss
    // FIX: DataService is @Observable, not ObservableObject
    // Use EnvironmentObject or direct access
    @EnvironmentObject private var dataService: DataService

    let pocket: Pocket

    @State private var amount: String = ""
    @State private var note: String = ""
    @State private var selectedWallet: Wallet?
    @State private var selectedDate: Date = Date()

    var wallets: [Wallet] {
        dataService.fetchWallets()
    }

    var isValid: Bool {
        let amountValue = Double(amount) ?? 0
        return amountValue > 0 && selectedWallet != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Jumlah Setor")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            Text("Rp")
                                .font(.title)
                                .foregroundStyle(.secondary)

                            TextField("0", text: $amount)
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                        }
                        .foregroundStyle(Color.incomeGreen)

                        if let wallet = selectedWallet {
                            Text("Saldo \(wallet.name): \(wallet.balance.formattedCurrency())")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Dari Dompet") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(wallets) { wallet in
                                DepositWalletButton(
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

                Section("Ke Pocket") {
                    HStack {
                        Image(systemName: pocket.icon)
                            .foregroundStyle(Color(hex: pocket.colorHex) ?? .gray)
                        Text(pocket.name)
                        Spacer()
                        Text(pocket.balance.formattedCurrency())
                            .fontWeight(.semibold)
                    }
                }

                Section("Detail") {
                    TextField("Catatan (opsional)", text: $note)
                    DatePicker("Tanggal", selection: $selectedDate, displayedComponents: [.date])
                }
            }
            .navigationTitle("Setor ke \(pocket.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Setor") {
                        performDeposit()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                selectedWallet = wallets.first
            }
        }
    }

    private func performDeposit() {
        guard let wallet = selectedWallet,
              let amountValue = Double(amount) else {
            return
        }

        // FIX: Use DataService.shared directly since it's @Observable
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

// MARK: - Custom Button
struct DepositWalletButton: View {
    let wallet: Wallet
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(hex: wallet.colorHex)?.opacity(0.15) ?? Color.gray.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: wallet.icon)
                        .font(.title3)
                        .foregroundStyle(Color(hex: wallet.colorHex) ?? .gray)
                }
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color(hex: wallet.colorHex) ?? .blue : Color.clear, lineWidth: 3)
                )

                Text(wallet.name)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 70)
            }
        }
        .buttonStyle(.plain)
    }
}
