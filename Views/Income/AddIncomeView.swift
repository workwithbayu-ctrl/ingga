import SwiftUI
import SwiftData
import FirebaseAuth

struct AddIncomeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    var onIncomeAdded: ((Double) -> Void)? = nil

    @FocusState private var isAmountFocused: Bool

    @State private var amount: String = ""
    @State private var note: String = ""
    @State private var selectedCategory: Category?
    @State private var selectedWallet: Wallet?
    @State private var selectedDate: Date = Date()
    @State private var isSaving = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var debugText: String = ""

    @State private var categories: [Category] = []
    @State private var wallets: [Wallet] = []

    // State untuk form kategori
    @State private var showAddCategory: Bool = false
    @State private var categoryToEdit: Category? = nil
    @State private var showEditCategory: Bool = false
    @State private var categoryToDelete: Category? = nil
    @State private var showDeleteConfirm: Bool = false

    // ⭐ FIX: sebelumnya bergantung ke `FirebaseAuthService.shared.currentUser`, yang TIDAK
    // PERNAH terisi (listener-nya tidak pernah dijalankan di app ini) — jadi `currentUser`
    // di sini selalu nil dan muncul error "User tidak ditemukan" saat simpan transaksi.
    // Sekarang resolve langsung dari Firebase Auth (sumber kebenaran login yang aktif)
    // dicocokkan dengan email di UserProfile/User lokal.
    private var currentUser: User? {
        let userDescriptor = FetchDescriptor<User>()
        let users = (try? modelContext.fetch(userDescriptor)) ?? []
        guard !users.isEmpty else { return nil }

        if let email = Auth.auth().currentUser?.email,
           let match = users.first(where: { $0.email == email }) {
            return match
        }
        return users.first
    }

    var isValid: Bool {
        let amountValue = Double(amount) ?? 0
        return amountValue > 0 && selectedCategory != nil && selectedWallet != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0B1220")?.ignoresSafeArea() ?? Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        amountCard

                        VStack(spacing: 20) {
                            categorySection
                            walletSection
                            noteSection
                            dateSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)

                        saveButton
                            .padding(.horizontal, 20)
                            .padding(.top, 32)
                            .padding(.bottom, 40)

                        Text(debugText)
                            .font(.caption2)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 20)
                    }
                }

                if showSuccess {
                    successOverlay
                }
            }
            .navigationTitle("Tambah Pemasukan")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Batal") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .toolbarBackground(Color(hex: "0B1220") ?? Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(isPresented: $showAddCategory, onDismiss: { refreshData() }) {
                CategoryFormView(defaultType: .income)
            }
            .sheet(isPresented: $showEditCategory, onDismiss: { refreshData() }) {
                if let category = categoryToEdit {
                    CategoryFormView(existingCategory: category)
                }
            }
            .alert("Hapus Kategori?", isPresented: $showDeleteConfirm) {
                Button("Batal", role: .cancel) {}
                Button("Hapus", role: .destructive) {
                    if let category = categoryToDelete {
                        deleteCategory(category)
                    }
                }
            } message: {
                if let category = categoryToDelete {
                    Text("Kategori '\(category.name)' akan dihapus permanen")
                }
            }
            .onAppear {
                refreshData()
            }
        }
        .tint(.white)
    }

    private func refreshData() {
        let dataService = DataService.shared

        categories = dataService.fetchCategories(type: .income)
        wallets = dataService.fetchWallets()
        let usr = currentUser

        debugText = "Cat:\(categories.count) Wallet:\(wallets.count) User:\(usr?.name ?? "nil")"

        if selectedCategory == nil, let firstCat = categories.first {
            selectedCategory = firstCat
        }
        if selectedWallet == nil, let firstWal = wallets.first {
            selectedWallet = firstWal
        }

        if categories.isEmpty {
            dataService.setupDefaultData()
            categories = dataService.fetchCategories(type: .income)
            wallets = dataService.fetchWallets()

            if selectedCategory == nil, let firstCat = categories.first {
                selectedCategory = firstCat
            }
            if selectedWallet == nil, let firstWal = wallets.first {
                selectedWallet = firstWal
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isAmountFocused = true
        }
    }

    private var amountCard: some View {
        VStack(spacing: 12) {
            Text("Jumlah Pemasukan")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))

            HStack(spacing: 4) {
                Text("Rp")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))

                TextField("0", text: $amount)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.leading)
                    .focused($isAmountFocused)
                    .onChange(of: amount) { _, newValue in
                        let filtered = newValue.filter { "0123456789".contains($0) }
                        if filtered != newValue {
                            amount = filtered
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.08))
        )
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("KATEGORI")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1)

                Spacer()

                Button {
                    showAddCategory = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                        Text("Tambah")
                            .font(.caption)
                    }
                    .foregroundColor(Color(hex: "64B4FF") ?? .blue)
                }
            }

            if categories.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.3))
                    Text("Belum ada kategori pemasukan")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.6))
                    Text("Tap 'Tambah' untuk buat kategori")
                        .font(.caption)
                        .foregroundColor(Color(hex: "64B4FF") ?? .blue)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(categories) { category in
                            CategoryButtonDark(
                                category: category,
                                isSelected: selectedCategory?.id == category.id
                            ) {
                                withAnimation(.spring(duration: 0.3)) {
                                    selectedCategory = category
                                }
                            }
                            .contextMenu {
                                Button {
                                    categoryToEdit = category
                                    showEditCategory = true
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }

                                Button(role: .destructive) {
                                    categoryToDelete = category
                                    showDeleteConfirm = true
                                } label: {
                                    Label("Hapus", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private var walletSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DOMPET")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.6))
                .tracking(1)

            if wallets.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "wallet.bifold")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.3))
                    Text("Belum ada dompet")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(wallets) { wallet in
                            WalletButtonDark(
                                wallet: wallet,
                                isSelected: selectedWallet?.id == wallet.id
                            ) {
                                withAnimation(.spring(duration: 0.3)) {
                                    selectedWallet = wallet
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CATATAN")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.6))
                .tracking(1)

            TextField("Tambahkan catatan...", text: $note, axis: .vertical)
                .font(.body)
                .foregroundColor(.white)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.08))
                )
        }
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TANGGAL")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.6))
                .tracking(1)

            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: "calendar")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedDate, style: .date)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)

                    Text(selectedDate, style: .time)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                    .labelsHidden()
                    .scaleEffect(0.9)
                    .colorMultiply(.white)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
            )
        }
    }

    private var saveButton: some View {
        Button {
            performSave()
        } label: {
            HStack(spacing: 12) {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title3)

                    Text("Simpan Pemasukan")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isValid ? Color.green : Color.white.opacity(0.15))
            )
        }
        .disabled(!isValid || isSaving)
        .buttonStyle(.plain)
    }

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)

                Text("Berhasil!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Pemasukan telah disimpan")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "1A2A4A") ?? Color.black)
                    .shadow(radius: 20)
            )
        }
    }

    private func performSave() {
        guard let category = selectedCategory else {
            errorMessage = "Pilih kategori"
            return
        }
        guard let wallet = selectedWallet else {
            errorMessage = "Pilih dompet"
            return
        }
        guard let user = currentUser else {
            errorMessage = "User tidak ditemukan. Coba logout dan login ulang."
            return
        }
        guard let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "Masukkan jumlah yang valid"
            return
        }

        isSaving = true

        DataService.shared.addIncome(
            amount: amountValue,
            note: note.isEmpty ? category.name : note,
            date: selectedDate,
            category: category,
            wallet: wallet,
            user: user
        )

        onIncomeAdded?(amountValue)

        withAnimation(.spring(duration: 0.3)) {
            showSuccess = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }

    // FIX: #Predicate - capture categoryID di luar closure
    private func deleteCategory(_ category: Category) {
        let categoryID = category.id

        let transactionDescriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { transaction in
                transaction.category?.id == categoryID
            }
        )
        let transactions = (try? modelContext.fetch(transactionDescriptor)) ?? []

        guard transactions.isEmpty else {
            errorMessage = "Kategori '\(category.name)' tidak bisa dihapus karena masih ada \(transactions.count) transaksi"
            return
        }

        modelContext.delete(category)
        try? modelContext.save()
        refreshData()
    }
}

// MARK: - Category Button Dark
struct CategoryButtonDark: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? (Color(hex: category.colorHex) ?? .blue).opacity(0.25) : Color.white.opacity(0.08))
                        .frame(width: 56, height: 56)

                    Image(systemName: category.icon)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? (Color(hex: category.colorHex) ?? .blue) : .white.opacity(0.7))
                }
                .overlay(
                    Circle()
                        .stroke(isSelected ? (Color(hex: category.colorHex) ?? .blue) : Color.clear, lineWidth: 2)
                )

                Text(category.name)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? (Color(hex: category.colorHex) ?? .blue) : .white.opacity(0.7))
                    .lineLimit(1)
                    .frame(width: 70)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Wallet Button Dark
struct WalletButtonDark: View {
    let wallet: Wallet
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? (Color(hex: wallet.colorHex) ?? .blue).opacity(0.25) : Color.white.opacity(0.08))
                        .frame(width: 56, height: 56)

                    Image(systemName: wallet.icon)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? (Color(hex: wallet.colorHex) ?? .blue) : .white.opacity(0.7))
                }
                .overlay(
                    Circle()
                        .stroke(isSelected ? (Color(hex: wallet.colorHex) ?? .blue) : Color.clear, lineWidth: 2)
                )

                Text(wallet.name)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? (Color(hex: wallet.colorHex) ?? .blue) : .white.opacity(0.7))
                    .lineLimit(1)
                    .frame(width: 70)
            }
        }
        .buttonStyle(.plain)
    }
}
