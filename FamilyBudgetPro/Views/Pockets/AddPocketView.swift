import SwiftUI
import SwiftData

struct AddPocketView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Wallet.name) private var wallets: [Wallet]

    @State private var selectedWallet: Wallet?
    @State private var name: String = ""
    @State private var targetAmount: String = ""
    @State private var allocationPercentage: String = "10"
    @State private var selectedColor: String = "#007AFF"
    @State private var selectedPocketType: PocketType = .dream
    @State private var showWalletPicker = false
    @State private var showTypePicker = false
    @State private var initialAmount: String = ""

    let colors: [(name: String, hex: String)] = [
        ("Biru", "#007AFF"),
        ("Hijau", "#34C759"),
        ("Merah", "#FF3B30"),
        ("Oranye", "#FF9500"),
        ("Ungu", "#AF52DE"),
        ("Kuning", "#FFCC00"),
        ("Pink", "#FF2D55"),
        ("Teal", "#5AC8FA"),
        ("Abu", "#8E8E93"),
        ("Coklat", "#A2845E")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                // Dark background
                Color(hex: "0B1220")?.ignoresSafeArea() ?? Color.black.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Rekening Picker
                        formSection(title: "Rekening") {
                            Button(action: { showWalletPicker = true }) {
                                HStack {
                                    HStack(spacing: 10) {
                                        if let wallet = selectedWallet {
                                            // FIX: Use wallet.icon instead of wallet.type.icon
                                            Image(systemName: wallet.icon)
                                                .font(.system(size: 18))
                                                .foregroundColor(.white)
                                            Text(wallet.name)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white)
                                        } else {
                                            Text("Pilih Rekening")
                                                .font(.system(size: 16))
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.4))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.08))
                                )
                            }
                        }

                        // Nama Pocket
                        formSection(title: "Nama Pocket") {
                            TextField("", text: $name, prompt: Text("Contoh: Dana Liburan").foregroundColor(.white.opacity(0.3)))
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.08))
                                )
                        }

                        // Tipe Pocket
                        formSection(title: "Tipe") {
                            Button(action: { showTypePicker = true }) {
                                HStack {
                                    HStack(spacing: 10) {
                                        Image(systemName: selectedPocketType.icon)
                                            .font(.system(size: 18))
                                            .foregroundColor(.white)
                                        Text(selectedPocketType.displayName)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.4))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.08))
                                )
                            }
                        }

                        // Target Jumlah
                        formSection(title: "Target Jumlah") {
                            TextField("", text: $targetAmount, prompt: Text("Rp0").foregroundColor(.white.opacity(0.3)))
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .keyboardType(.numberPad)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.08))
                                )
                        }

                        // Dana Awal (NEW)
                        formSection(title: "Dana Awal (Opsional)") {
                            VStack(alignment: .leading, spacing: 8) {
                                TextField("", text: $initialAmount, prompt: Text("Rp0").foregroundColor(.white.opacity(0.3)))
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .keyboardType(.numberPad)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white.opacity(0.08))
                                    )

                                if let wallet = selectedWallet {
                                    Text("Saldo tersedia: Rp \(formattedAmount(wallet.balance))")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.5))
                                        .padding(.horizontal, 4)
                                }
                            }
                        }

                        // Persentase Alokasi
                        formSection(title: "Persentase Alokasi") {
                            VStack(alignment: .leading, spacing: 8) {
                                TextField("", text: $allocationPercentage, prompt: Text("10").foregroundColor(.white.opacity(0.3)))
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .keyboardType(.numberPad)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white.opacity(0.08))
                                    )

                                Text("Persentase dari pemasukan yang akan dialokasikan otomatis ke pocket ini")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(.horizontal, 4)
                            }
                        }

                        // Warna
                        formSection(title: "Warna") {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                                ForEach(colors, id: \.hex) { color in
                                    Button(action: {
                                        selectedColor = color.hex
                                    }) {
                                        Circle()
                                            .fill(Color(hex: color.hex) ?? .blue)
                                            .frame(width: 48, height: 48)
                                            .overlay(
                                                Circle()
                                                    .stroke(selectedColor == color.hex ? Color.white : Color.clear, lineWidth: 3)
                                            )
                                            .overlay(
                                                selectedColor == color.hex ?
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(.white)
                                                : nil
                                            )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Pocket Baru")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan") {
                        savePocket()
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                    .disabled(selectedWallet == nil || name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if selectedWallet == nil, let first = wallets.first {
                    selectedWallet = first
                }
                // Auto-fill defaults from selected type
                if targetAmount.isEmpty {
                    targetAmount = String(format: "%.0f", selectedPocketType.defaultTarget)
                }
                if allocationPercentage.isEmpty {
                    allocationPercentage = String(format: "%.0f", selectedPocketType.defaultAllocation)
                }
            }
            .sheet(isPresented: $showWalletPicker) {
                WalletPickerSheetPocket(
                    wallets: wallets,
                    selectedWallet: $selectedWallet
                )
            }
            .sheet(isPresented: $showTypePicker) {
                TypePickerSheet(
                    selectedType: $selectedPocketType
                )
            }
        }
    }

    @ViewBuilder
    private func formSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 4)
            content()
        }
    }

    private func savePocket() {
        guard let wallet = selectedWallet else { return }

        // Bersihkan target amount dari karakter non-numeric
        let cleanTarget = targetAmount.replacingOccurrences(of: ".", with: "")
                                      .replacingOccurrences(of: ",", with: "")
        guard let target = Double(cleanTarget), target > 0 else { return }

        guard let percentage = Double(allocationPercentage), percentage > 0 else { return }

        // Parse dana awal
        let cleanInitial = initialAmount.replacingOccurrences(of: ".", with: "")
                                        .replacingOccurrences(of: ",", with: "")
        let initial = Double(cleanInitial) ?? 0

        // Validasi dana awal tidak melebihi saldo wallet
        guard wallet.balance >= initial else {
            // TODO: Show alert
            return
        }

        // Kurangi saldo wallet jika ada dana awal
        if initial > 0 {
            wallet.balance -= initial
            wallet.updatedAt = Date()
        }

        let pocket = Pocket(
            name: name.trimmingCharacters(in: .whitespaces),
            pocketType: selectedPocketType,
            targetAmount: target,
            balance: initial,
            allocationPercentage: percentage,
            icon: selectedPocketType.icon,
            colorHex: selectedColor,
            walletID: wallet.id,
            isDefault: false
        )

        modelContext.insert(pocket)
        try? modelContext.save()
        dismiss()
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

// MARK: - Wallet Picker Sheet (RENAMED)
struct WalletPickerSheetPocket: View {
    let wallets: [Wallet]
    @Binding var selectedWallet: Wallet?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0B1220")?.ignoresSafeArea() ?? Color.black.ignoresSafeArea()

                // FIX: Use ForEach with explicit id
                List {
                    ForEach(wallets, id: \.id) { wallet in
                        Button(action: {
                            selectedWallet = wallet
                            dismiss()
                        }) {
                            HStack {
                                // FIX: Use wallet.icon instead of wallet.type.icon
                                Image(systemName: wallet.icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                Text(wallet.name)
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)

                                Spacer()

                                if selectedWallet?.id == wallet.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.05))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Pilih Rekening")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Tutup") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Type Picker Sheet
struct TypePickerSheet: View {
    @Binding var selectedType: PocketType
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0B1220")?.ignoresSafeArea() ?? Color.black.ignoresSafeArea()

                List(PocketType.allCases, id: \.self) { type in
                    Button(action: {
                        selectedType = type
                        dismiss()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: type.icon)
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color(hex: type.color)?.opacity(0.3) ?? Color.white.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            Text(type.displayName)
                                .font(.system(size: 16))
                                .foregroundColor(.white)

                            Spacer()

                            if selectedType == type {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Pilih Tipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Tutup") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
}
