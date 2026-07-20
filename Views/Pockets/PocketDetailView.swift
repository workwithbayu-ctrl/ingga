import SwiftUI
import SwiftData

struct PocketDetailView: View {
    @StateObject private var dataService = DataService.shared

    let pocket: Pocket

    @Environment(\.dismiss) private var dismiss
    @State private var showingDeposit = false
    @State private var showingWithdraw = false
    @State private var showingTransfer = false
    @State private var showingEdit = false
    @State private var refreshTrigger = UUID()
    @State private var editedName: String = ""
    @State private var editedTarget: String = ""
    @State private var editedAllocation: String = ""

    var transactions: [PocketTransaction] {
        dataService.fetchPocketTransactions(for: pocket)
    }

    var associatedWallet: Wallet? {
        guard let walletID = pocket.walletID else { return nil }
        return dataService.fetchWallets().first { $0.id == walletID }
    }

    var body: some View {
        ZStack {
            // Dark background
            Color(hex: "0B1220")?.ignoresSafeArea() ?? Color.black.ignoresSafeArea()

            List {
                // MARK: - Info Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: pocket.icon)
                                .font(.title2)
                                .foregroundStyle(Color(hex: pocket.colorHex) ?? .gray)

                            Text(pocket.name)
                                .font(.title2.bold())
                                .foregroundColor(.white)

                            Spacer()

                            Text(pocket.pocketType.displayName)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Capsule())
                                .foregroundColor(.white)
                        }

                        // Show associated wallet
                        if let wallet = associatedWallet {
                            HStack {
                                Image(systemName: wallet.icon)
                                    .foregroundStyle(Color(hex: wallet.colorHex) ?? .gray)
                                Text("Rekening: \(wallet.name)")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }

                        Text("Rp \(formattedAmount(pocket.balance))")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        if pocket.targetAmount > 0 {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Target: Rp \(formattedAmount(pocket.targetAmount))")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.6))

                                    Spacer()

                                    Text(pocket.formattedProgress)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color(hex: pocket.colorHex) ?? .gray)
                                }

                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.white.opacity(0.15))
                                            .frame(height: 8)

                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color(hex: pocket.colorHex) ?? .gray)
                                            .frame(width: geo.size.width * CGFloat(pocket.progress), height: 8)
                                    }
                                }
                                .frame(height: 8)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.white.opacity(0.05))

                // MARK: - Action Buttons
                Section {
                    HStack(spacing: 12) {
                        Button {
                            showingDeposit = true
                        } label: {
                            Label("Setor", systemImage: "arrow.down.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(.green)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.green.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)

                        Button {
                            showingWithdraw = true
                        } label: {
                            Label("Tarik", systemImage: "arrow.up.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.red.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)

                        Button {
                            showingTransfer = true
                        } label: {
                            Label("Transfer", systemImage: "arrow.left.arrow.right")
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.blue.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listRowBackground(Color.clear)

                // MARK: - Edit Section
                Section {
                    Button {
                        editedName = pocket.name
                        editedTarget = String(Int(pocket.targetAmount))
                        editedAllocation = String(Int(pocket.allocationPercentage))
                        showingEdit = true
                    } label: {
                        Label("Edit Pocket", systemImage: "pencil")
                            .foregroundColor(.white)
                    }

                    Button(role: .destructive) {
                        DataService.shared.deletePocket(pocket)
                        dismiss()
                    } label: {
                        Label("Hapus Pocket", systemImage: "trash")
                    }
                }
                .listRowBackground(Color.white.opacity(0.05))

                // MARK: - Transaction History
                Section {
                    if transactions.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 48))
                                .foregroundStyle(.white.opacity(0.3))
                            Text("Belum Ada Transaksi")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Setor atau tarik untuk melihat riwayat")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(transactions) { transaction in
                            PocketTransactionRow(transaction: transaction)
                        }
                    }
                } header: {
                    Text("Riwayat Transaksi")
                        .foregroundColor(.white.opacity(0.7))
                }
                .listRowBackground(Color.white.opacity(0.05))
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(pocket.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Selesai") {
                    dismiss()
                }
                .foregroundColor(.white)
            }
        }
        .sheet(isPresented: $showingDeposit) {
            PocketDepositView(pocket: pocket)
        }
        .sheet(isPresented: $showingWithdraw) {
            PocketWithdrawView(pocket: pocket)
        }
        .sheet(isPresented: $showingTransfer) {
            PocketTransferView(sourcePocket: pocket)
        }
        .sheet(isPresented: $showingEdit) {
            NavigationStack {
                ZStack {
                    Color(hex: "0B1220")?.ignoresSafeArea() ?? Color.black.ignoresSafeArea()

                    Form {
                        Section("Nama") {
                            TextField("Nama Pocket", text: $editedName)
                                .foregroundColor(.white)
                        }
                        .listRowBackground(Color.white.opacity(0.05))

                        Section("Target") {
                            TextField("Target Jumlah", text: $editedTarget)
                                .keyboardType(.numberPad)
                                .foregroundColor(.white)
                        }
                        .listRowBackground(Color.white.opacity(0.05))

                        Section("Alokasi (%)") {
                            TextField("Persentase", text: $editedAllocation)
                                .keyboardType(.numberPad)
                                .foregroundColor(.white)
                        }
                        .listRowBackground(Color.white.opacity(0.05))
                    }
                    .scrollContentBackground(.hidden)
                }
                .navigationTitle("Edit Pocket")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Batal") { showingEdit = false }
                            .foregroundColor(.white)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Simpan") {
                            let target = Double(editedTarget) ?? pocket.targetAmount
                            let allocation = Double(editedAllocation) ?? pocket.allocationPercentage

                            dataService.updatePocket(
                                pocket,
                                name: editedName,
                                targetAmount: target,
                                allocationPercentage: allocation
                            )
                            showingEdit = false
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
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

// MARK: - Pocket Transaction Row
struct PocketTransactionRow: View {
    let transaction: PocketTransaction

    var body: some View {
        HStack {
            Image(systemName: transaction.isDeposit ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundStyle(transaction.isDeposit ? .green : .red)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.note.isEmpty ? (transaction.isDeposit ? "Setor" : "Tarik") : transaction.note)
                    .font(.subheadline)
                    .foregroundColor(.white)

                Text(transaction.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Text("Rp \(formattedAmount(transaction.amount))")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(transaction.isDeposit ? .green : .red)
        }
        .padding(.vertical, 4)
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
