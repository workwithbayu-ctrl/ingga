import SwiftUI
import SwiftData

// MARK: - Wallet Type Button (Custom segmented control)
struct WalletTypeButton: View {
    let type: WalletType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 20))

                Text(type.displayName)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.5))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: "64B4FF")!.opacity(0.25) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(hex: "64B4FF")! : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

struct AddWalletView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedBank: IndonesianBank = .bca
    @State private var customName = ""
    @State private var accountNumber = ""
    @State private var selectedType: WalletType = .bank
    @State private var initialBalance = ""
    @State private var accountHolder = ""

    // Filtered banks based on type
    private var filteredBanks: [IndonesianBank] {
        switch selectedType {
        case .bank:
            return IndonesianBank.conventionalBanks
        case .digitalBank:
            return IndonesianBank.digitalBanks
        case .cash:
            return [.cash]
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0B1220")!
                    .ignoresSafeArea()

                Form {
                    // Wallet Type - Custom buttons (more responsive than Picker segmented)
                    Section {
                        HStack(spacing: 8) {
                            ForEach(WalletType.allCases, id: \.self) { type in
                                WalletTypeButton(
                                    type: type,
                                    isSelected: selectedType == type
                                ) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedType = type
                                        // Reset selectedBank to valid option for new type
                                        switch type {
                                        case .bank:
                                            selectedBank = .bca
                                        case .digitalBank:
                                            selectedBank = .jago
                                        case .cash:
                                            selectedBank = .cash
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Color.white.opacity(0.05))
                    } header: {
                        Text("Tipe Dompet")
                            .foregroundColor(.gray)
                    }

                    // Bank Selection
                    Section {
                        Picker("Bank", selection: $selectedBank) {
                            ForEach(filteredBanks, id: \.self) { bank in
                                Text(bank.name).tag(bank)
                            }
                        }
                        .pickerStyle(.navigationLink)
                        .foregroundColor(.white)
                        .listRowBackground(Color.white.opacity(0.05))
                    } header: {
                        Text("Pilih Bank")
                            .foregroundColor(.gray)
                    }

                    // Custom Name
                    Section {
                        TextField("Nama Rekening (opsional)", text: $customName)
                            .foregroundColor(.white)
                            .listRowBackground(Color.white.opacity(0.05))
                    } header: {
                        Text("Nama Rekening")
                            .foregroundColor(.gray)
                    } footer: {
                        Text("Contoh: BCA Gaji, Dompet Harian")
                            .foregroundColor(.gray.opacity(0.7))
                    }

                    // Account Holder
                    if selectedType != .cash {
                        Section {
                            TextField("Nama Pemilik Rekening", text: $accountHolder)
                                .foregroundColor(.white)
                                .listRowBackground(Color.white.opacity(0.05))
                        } header: {
                            Text("Nama Pemilik")
                                .foregroundColor(.gray)
                        }
                    }

                    // Account Number
                    if selectedType != .cash {
                        Section {
                            TextField("Nomor Rekening", text: $accountNumber)
                                .keyboardType(.numberPad)
                                .foregroundColor(.white)
                                .listRowBackground(Color.white.opacity(0.05))
                        } header: {
                            Text("Nomor Rekening")
                                .foregroundColor(.gray)
                        }
                    }

                    // Initial Balance
                    Section {
                        TextField("Saldo Awal", text: $initialBalance)
                            .keyboardType(.decimalPad)
                            .foregroundColor(.white)
                            .listRowBackground(Color.white.opacity(0.05))
                    } header: {
                        Text("Saldo Awal")
                            .foregroundColor(.gray)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Tambah Rekening")
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
                }
            }
        }
    }

    private func saveWallet() {
        let maxSort = (try? modelContext.fetch(FetchDescriptor<Wallet>()).map(\.sortOrder).max()) ?? 0

        let name = customName.isEmpty ? selectedBank.name : customName
        let balance = Double(initialBalance) ?? 0

        let wallet = Wallet(
            name: name,
            type: selectedType,
            bankCode: selectedBank.code,
            accountNumber: accountNumber.isEmpty ? nil : accountNumber,
            balance: balance,
            icon: selectedType.icon,
            colorHex: walletColor(for: selectedBank),
            accountHolder: accountHolder.isEmpty ? nil : accountHolder,
            sortOrder: maxSort + 1
        )

        modelContext.insert(wallet)
        try? modelContext.save()
        dismiss()
    }

    private func walletColor(for bank: IndonesianBank) -> String {
        switch bank {
        case .bca, .bcaSyariah, .blu: return "0060AF"
        case .mandiri, .mandiriSyariah, .livin: return "003D79"
        case .bni, .bniSyariah: return "F15A23"
        case .bri: return "00529C"
        case .btn: return "ED1C24"
        case .bsi: return "00A651"
        case .jago: return "FF6B35"
        case .seabank: return "003B5C"
        case .cash: return "00D26A"
        default: return "4D96FF"
        }
    }
}
