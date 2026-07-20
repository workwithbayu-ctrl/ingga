import SwiftUI
import SwiftData

struct AddWalletView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedIcon = "💳"
    @State private var selectedType: WalletType = .cash
    @State private var initialBalance = ""
    @State private var colorHex = "#1a1a2e"
    @State private var accountHolder = ""

    let icons = ["💳", "🏦", "💰", "💵", "💶", "💷", "💴", "🪙", "📱", "🧧"]
    let colors = ["#1a1a2e", "#16213e", "#0f3460", "#533483", "#e94560", "#16c79a", "#ef476f", "#ffd166", "#118ab2", "#073b4c"]

    var body: some View {
        NavigationStack {
            Form {
                // Name Section
                Section("Nama Rekening") {
                    TextField("Contoh: Dompet Utama", text: $name)
                }

                // Account Holder
                Section("Pemilik Rekening") {
                    TextField("Nama pemilik", text: $accountHolder)
                }

                // Icon Section
                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Button(action: {
                                selectedIcon = icon
                            }) {
                                Text(icon)
                                    .font(.system(size: 28))
                                    .frame(width: 44, height: 44)
                                    .background(
                                        selectedIcon == icon ?
                                        Color.blue.opacity(0.2) :
                                        Color.clear
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                selectedIcon == icon ?
                                                Color.blue :
                                                Color.gray.opacity(0.3),
                                                lineWidth: selectedIcon == icon ? 2 : 1
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Color Section
                Section("Warna") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Button(action: {
                                colorHex = color
                            }) {
                                Circle()
                                    .fill(Color(hex: color) ?? Color.gray)
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                colorHex == color ?
                                                Color.white :
                                                Color.clear,
                                                lineWidth: 3
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Type Section
                Section("Tipe") {
                    Picker("Tipe", selection: $selectedType) {
                        ForEach(WalletType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Initial Balance Section
                Section("Saldo Awal") {
                    HStack {
                        Text("Rp")
                            .foregroundStyle(.secondary)
                        TextField("0", text: $initialBalance)
                            .keyboardType(.numberPad)
                    }
                }
            }
            .navigationTitle("Tambah Rekening")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Batal") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Simpan") {
                        saveWallet()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveWallet() {
        let balance = Double(initialBalance.replacingOccurrences(of: ".", with: "")) ?? 0

        let wallet = Wallet(
            name: name,
            type: selectedType,
            balance: balance,
            icon: selectedIcon,
            colorHex: colorHex,
            accountHolder: accountHolder.isEmpty ? name : accountHolder
        )

        modelContext.insert(wallet)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving wallet: \(error)")
        }
    }
}
