import SwiftUI
import SwiftData

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var authService = FirebaseAuthService.shared

    private var dataService = DataService.shared

    var onExpenseAdded: ((Double) -> Void)? = nil

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

    @State private var expandedParent: Category?

    private var currentUser: User? {
        let descriptor = FetchDescriptor<User>()
        let users = (try? modelContext.fetch(descriptor)) ?? []
        if let currentRole = authService.currentUser?.role {
            return users.first { $0.role == currentRole }
        }
        return users.first
    }

    var selectedWalletBalance: Double {
        guard let wallet = selectedWallet else { return 0 }
        let latestWallets = dataService.fetchWallets()
        return latestWallets.first(where: { $0.id == wallet.id })?.balance ?? 0
    }

    var isValid: Bool {
        let amountValue = Double(amount) ?? 0
        guard let wallet = selectedWallet else { return false }
        let latestWallets = dataService.fetchWallets()
        guard let latestWallet = latestWallets.first(where: { $0.id == wallet.id }) else { return false }

        return amountValue > 0
            && amountValue <= latestWallet.balance
            && selectedCategory != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0B1220")?.ignoresSafeArea() ?? Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        walletSection
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        amountCard

                        if let wallet = selectedWallet,
                           let amountValue = Double(amount),
                           amountValue > 0,
                           amountValue > selectedWalletBalance {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.orange)
                                Text("Saldo \(wallet.name) tidak cukup! Tersedia: \(selectedWalletBalance.formattedCurrency())")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                        }

                        VStack(spacing: 20) {
                            categoryDropdownSection
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
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                    }
                }

                if showSuccess {
                    successOverlay
                }
            }
            .navigationTitle("Tambah Pengeluaran")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color(hex: "0B1220") ?? Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Batal") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .onAppear {
                loadData()
            }
        }
        .tint(.white)
    }

    private func loadData() {
        let allCats = dataService.fetchCategoriesWithSubcategories(type: .expense)
        categories = allCats.map(\.parent)
        wallets = dataService.fetchWallets()
        let usr = currentUser

        debugText = "Cat:\(categories.count) Wallet:\(wallets.count) User:\(usr?.name ?? "nil")"

        if selectedWallet == nil, let firstWal = wallets.first {
            selectedWallet = firstWal
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isAmountFocused = true
        }
    }

    private var walletSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DOMPET")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.6))
                .tracking(1)

            if wallets.isEmpty {
                emptyWalletView
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(wallets) { wallet in
                            CompactWalletButtonDark(
                                wallet: wallet,
                                isSelected: selectedWallet?.id == wallet.id
                            ) {
                                withAnimation(.spring(duration: 0.3)) {
                                    selectedWallet = wallet
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var emptyWalletView: some View {
        VStack(spacing: 6) {
            Image(systemName: "wallet.bifold")
                .font(.system(size: 24))
                .foregroundColor(.white.opacity(0.3))
            Text("Belum ada dompet")
                .font(.body)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 16)
    }

    private var amountCard: some View {
        VStack(spacing: 10) {
            Text("Jumlah Pengeluaran")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))

            HStack(spacing: 4) {
                Text("Rp")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))

                TextField("0", text: $amount)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.red)
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

            if let wallet = selectedWallet {
                HStack(spacing: 4) {
                    Text("Saldo \(wallet.name):")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                    Text(selectedWalletBalance.formattedCurrency())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(selectedWalletBalance >= (Double(amount) ?? 0) ? .green : .red)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.08))
        )
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var categoryDropdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("KATEGORI")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.6))
                .tracking(1)

            if categories.isEmpty {
                emptyCategoryView
            } else if let selected = selectedCategory {
                selectedCategoryView(category: selected)
            } else {
                categoryDropdownList
            }
        }
    }

    private var emptyCategoryView: some View {
        VStack(spacing: 6) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 24))
                .foregroundColor(.white.opacity(0.3))
            Text("Belum ada kategori")
                .font(.body)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 16)
    }

    private func selectedCategoryView(category: Category) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: category.icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: category.colorHex) ?? .gray)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill((Color(hex: category.colorHex) ?? .gray).opacity(0.15))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    if let parentId = category.parentCategory,
                       let parent = categories.first(where: { $0.id.uuidString == parentId }) {
                        Text(parent.name)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                Spacer()

                Button("Ganti") {
                    withAnimation {
                        selectedCategory = nil
                        expandedParent = nil
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.15))
                .cornerRadius(8)
            }
            .padding(12)
            .background(Color.white.opacity(0.08))
            .cornerRadius(12)
        }
    }

    private var categoryDropdownList: some View {
        let grouped = dataService.fetchCategoriesWithSubcategories(type: .expense)

        return VStack(spacing: 8) {
            ForEach(grouped, id: \.parent.id) { group in
                CategoryParentRowDark(
                    parent: group.parent,
                    subcategories: group.subcategories,
                    isExpanded: expandedParent?.id == group.parent.id,
                    selectedCategory: selectedCategory
                ) {
                    withAnimation(.spring(duration: 0.3)) {
                        if expandedParent?.id == group.parent.id {
                            expandedParent = nil
                        } else {
                            expandedParent = group.parent
                        }
                    }
                } onSelectSub: { sub in
                    withAnimation(.spring(duration: 0.3)) {
                        selectedCategory = sub
                        expandedParent = nil
                    }
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
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
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

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: "calendar")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                }

                VStack(alignment: .leading, spacing: 2) {
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
                    .scaleEffect(0.85)
                    .colorMultiply(.white)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.08))
            )
        }
    }

    private var saveButton: some View {
        Button {
            performSave()
        } label: {
            HStack(spacing: 10) {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title3)

                    Text("Simpan Pengeluaran")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isValid ? Color.red : Color.white.opacity(0.15))
            )
        }
        .disabled(!isValid || isSaving)
        .buttonStyle(.plain)
    }

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.green)

                Text("Berhasil!")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Pengeluaran telah disimpan")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "1A2A4A") ?? Color.black)
                    .shadow(radius: 16)
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
            errorMessage = "User tidak ditemukan"
            return
        }
        guard let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "Masukkan jumlah yang valid"
            return
        }

        let latestWallets = dataService.fetchWallets()
        guard let latestWallet = latestWallets.first(where: { $0.id == wallet.id }) else {
            errorMessage = "Dompet tidak ditemukan"
            return
        }
        guard latestWallet.balance >= amountValue else {
            errorMessage = "Saldo \(latestWallet.name) tidak cukup!"
            return
        }

        isSaving = true

        dataService.addExpense(
            amount: amountValue,
            note: note.isEmpty ? category.name : note,
            date: selectedDate,
            category: category,
            wallet: wallet,
            user: user
        )

        onExpenseAdded?(amountValue)

        withAnimation(.spring(duration: 0.3)) {
            showSuccess = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}

// MARK: - Compact Wallet Button Dark
struct CompactWalletButtonDark: View {
    let wallet: Wallet
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: wallet.icon)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: wallet.colorHex) ?? .blue)

                Text(wallet.name)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(.white)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue.opacity(0.15) : Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
            )
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Parent Row Dark
struct CategoryParentRowDark: View {
    let parent: Category
    let subcategories: [Category]
    let isExpanded: Bool
    let selectedCategory: Category?
    let onExpand: () -> Void
    let onSelectSub: (Category) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onExpand) {
                HStack(spacing: 10) {
                    Image(systemName: parent.icon)
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: parent.colorHex) ?? .gray)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill((Color(hex: parent.colorHex) ?? .gray).opacity(0.15))
                        )

                    Text(parent.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.08))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)

            if isExpanded {
                if subcategories.isEmpty {
                    Button {
                        onSelectSub(parent)
                    } label: {
                        Text("Pilih \(parent.name)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(hex: parent.colorHex) ?? .blue)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 12)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 70, maximum: 80))], spacing: 10) {
                        ForEach(subcategories) { sub in
                            SubCategoryGridItemDark(
                                category: sub,
                                isSelected: selectedCategory?.id == sub.id
                            ) {
                                onSelectSub(sub)
                            }
                        }
                    }
                    .padding(.top, 10)
                    .padding(.horizontal, 8)
                }
            }
        }
    }
}

// MARK: - Sub Category Grid Item Dark
struct SubCategoryGridItemDark: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? (Color(hex: category.colorHex) ?? .blue).opacity(0.2) : Color.white.opacity(0.06))
                        .frame(width: 44, height: 44)

                    Image(systemName: category.icon)
                        .font(.system(size: 18))
                        .foregroundColor(isSelected ? (Color(hex: category.colorHex) ?? .blue) : .white.opacity(0.7))
                }

                Text(category.name)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? (Color(hex: category.colorHex) ?? .blue) : .white.opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .buttonStyle(.plain)
        .frame(width: 70)
    }
}
