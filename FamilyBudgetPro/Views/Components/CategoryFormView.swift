import SwiftUI
import SwiftData

struct CategoryFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var existingCategory: Category? = nil
    var parentCategory: Category? = nil
    var defaultType: TransactionType = .expense
    
    @State private var name: String = ""
    @State private var selectedType: TransactionType
    @State private var selectedIcon: String = "tag.fill"
    @State private var selectedColorHex: String = "64B4FF"
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage: String = ""
    
    @State private var existingCategories: [Category] = []
    
    let iconOptions = [
        "tag.fill", "cart.fill", "car.fill", "house.fill",
        "fork.knife", "heart.fill", "graduationcap.fill", "briefcase.fill",
        "airplane", "gift.fill", "bolt.fill", "wifi",
        "phone.fill", "gamecontroller.fill", "pawprint.fill", "leaf.fill",
        "drop.fill", "sparkles", "face.smiling.fill", "tshirt.fill",
        "hand.raised.fill", "mouth.fill", "figure.child", "rectangle.fill",
        "cup.and.saucer.fill", "cross.case.fill", "person.2.fill", "person.fill",
        "person.fill.checkmark", "fuel.pump.fill", "bicycle", "tv.fill",
        "ellipsis.circle.fill", "ellipsis", "dollarsign.circle.fill",
        "laptopcomputer", "chart.line.uptrend.xyaxis", "bag.fill", "carrot.fill"
    ]
    
    let colorOptions = [
        "64B4FF", "4ADE80", "F87171", "FBBF24",
        "A78BFA", "F472B6", "2DD4BF", "FB923C",
        "E879F9", "60A5FA", "34D399", "FF6B22",
        "FF3B30", "FF9500", "5856D6", "AF52DE",
        "007AFF", "00C7BE", "FF2D55", "8E8E93"
    ]
    
    var isEditing: Bool {
        existingCategory != nil
    }
    
    var isSubcategory: Bool {
        parentCategory != nil
    }
    
    var isValid: Bool {
        guard !name.isEmpty else { return false }
        return true
    }
    
    var navigationTitle: String {
        if isEditing {
            return "Edit Kategori"
        } else if isSubcategory {
            return "Tambah Sub Kategori"
        } else {
            return "Tambah Kategori"
        }
    }
    
    init(existingCategory: Category? = nil, parentCategory: Category? = nil, defaultType: TransactionType = .expense) {
        self.existingCategory = existingCategory
        self.parentCategory = parentCategory
        self.defaultType = defaultType
        _selectedType = State(initialValue: existingCategory?.type ?? defaultType)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                (Color(hex: "0B1220")!).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        if isSubcategory, let parent = parentCategory {
                            subcategoryInfoBanner(parent: parent)
                        }
                        
                        if !isEditing && !isSubcategory {
                            typeSection
                        }
                        
                        nameSection
                        iconSection
                        colorSection
                        previewSection
                        saveButton
                        
                        if isEditing {
                            deleteButton
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Batal") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .toolbarBackground(Color(hex: "0B1220")!, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("Error", isPresented: $showError) {
                Button("OK") { showError = false }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                loadExistingCategories()
                if let existing = existingCategory {
                    name = existing.name
                    selectedType = existing.type
                    selectedIcon = existing.icon
                    selectedColorHex = existing.colorHex
                }
            }
        }
        .tint(.white)
    }
    
    private func subcategoryInfoBanner(parent: Category) -> some View {
        HStack(spacing: 12) {
            Image(systemName: parent.icon)
                .font(.system(size: 20))
                .foregroundColor(Color(hex: parent.colorHex)!)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Sub kategori untuk:")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                Text(parent.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill((Color(hex: parent.colorHex)!).opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke((Color(hex: parent.colorHex)!).opacity(0.3), lineWidth: 1)
        )
    }
    
    private var typeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TIPE KATEGORI")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.6))
                .tracking(1)
            
            HStack(spacing: 12) {
                TypeButtonDark(
                    title: "Pemasukan",
                    icon: "arrow.down",
                    isSelected: selectedType == .income,
                    color: .green
                ) {
                    withAnimation(.spring(duration: 0.3)) {
                        selectedType = .income
                    }
                }
                
                TypeButtonDark(
                    title: "Pengeluaran",
                    icon: "arrow.up",
                    isSelected: selectedType == .expense,
                    color: .red
                ) {
                    withAnimation(.spring(duration: 0.3)) {
                        selectedType = .expense
                    }
                }
            }
        }
    }
    
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NAMA KATEGORI")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.6))
                .tracking(1)
            
            TextField("Contoh: Makanan, Transport, Gaji...", text: $name)
                .font(.body)
                .foregroundColor(.white)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.08))
                )
        }
    }
    
    private var iconSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("IKON")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.6))
                .tracking(1)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 52))], spacing: 10) {
                ForEach(iconOptions, id: \.self) { icon in
                    IconButtonDark(
                        icon: icon,
                        isSelected: selectedIcon == icon,
                        colorHex: selectedColorHex
                    ) {
                        withAnimation(.spring(duration: 0.2)) {
                            selectedIcon = icon
                        }
                    }
                }
            }
        }
    }
    
    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WARNA")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.6))
                .tracking(1)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
                ForEach(colorOptions, id: \.self) { color in
                    ColorButtonDark(
                        colorHex: color,
                        isSelected: selectedColorHex == color
                    ) {
                        withAnimation(.spring(duration: 0.2)) {
                            selectedColorHex = color
                        }
                    }
                }
            }
        }
    }
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PREVIEW")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.6))
                .tracking(1)
            
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill((Color(hex: selectedColorHex)!).opacity(0.2))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: selectedIcon)
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: selectedColorHex)!)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(name.isEmpty ? "Nama Kategori" : name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 6) {
                        Text(selectedType == .income ? "Pemasukan" : "Pengeluaran")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(selectedType == .income ? .green : .red)
                        
                        if isSubcategory, let parent = parentCategory {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.4))
                            
                            Text("Sub: \(parent.name)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        } else if !isSubcategory {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.4))
                            
                            Text("Kategori Utama")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
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
                    Image(systemName: isEditing ? "pencil.circle.fill" : "checkmark.circle.fill")
                        .font(.title3)
                    
                    Text(isEditing ? "Simpan Perubahan" : "Simpan Kategori")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isValid ? (Color(hex: selectedColorHex)!) : Color.white.opacity(0.15))
            )
        }
        .disabled(!isValid || isSaving)
        .buttonStyle(.plain)
    }
    
    private var deleteButton: some View {
        Button {
            performDelete()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "trash.fill")
                    .font(.title3)
                
                Text("Hapus Kategori")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.red.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.red.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
        .padding(.bottom, 40)
    }
    
    private func loadExistingCategories() {
        let descriptor = FetchDescriptor<Category>()
        existingCategories = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    private func performSave() {
        guard !name.isEmpty else { return }
        
        if isSubcategory, let parent = parentCategory {
            let existingSub = existingCategories.filter {
                $0.parentCategory?.id == parent.id &&
                $0.name.lowercased() == name.lowercased() &&
                $0.id != existingCategory?.id
            }
            if !existingSub.isEmpty {
                errorMessage = "Sub kategori '\(name)' sudah ada di \(parent.name)"
                showError = true
                return
            }
        }
        
        if !isSubcategory {
            let existing = existingCategories.filter {
                $0.parentCategory == nil &&
                $0.name.lowercased() == name.lowercased() &&
                $0.type == selectedType &&
                $0.id != existingCategory?.id
            }
            if !existing.isEmpty {
                errorMessage = "Kategori '\(name)' sudah ada"
                showError = true
                return
            }
        }
        
        isSaving = true
        
        if let existing = existingCategory {
            existing.name = name
            existing.icon = selectedIcon
            existing.colorHex = selectedColorHex
        } else {
            let category = Category(
                name: name,
                type: selectedType,
                icon: selectedIcon,
                colorHex: selectedColorHex,
                parentCategory: isSubcategory ? parentCategory : nil,
                isDefault: false
            )
            modelContext.insert(category)
        }
        
        try? modelContext.save()
        dismiss()
    }
    
    // ✅ FIX: #Predicate — capture categoryID di luar closure
    private func performDelete() {
        guard let category = existingCategory else { return }
        
        let categoryID = category.id  // ✅ Capture di luar
        
        let transactionDescriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { transaction in
                transaction.category?.id == categoryID  // ✅ Pakai variable capture
            }
        )
        let transactions = (try? modelContext.fetch(transactionDescriptor)) ?? []
        
        let subcategories = existingCategories.filter { $0.parentCategory?.id == categoryID }
        
        if !transactions.isEmpty {
            errorMessage = "Kategori '\(category.name)' tidak bisa dihapus karena masih ada \(transactions.count) transaksi"
            showError = true
            return
        }
        
        if !subcategories.isEmpty {
            errorMessage = "Kategori '\(category.name)' tidak bisa dihapus karena masih ada \(subcategories.count) sub kategori"
            showError = true
            return
        }
        
        modelContext.delete(category)
        try? modelContext.save()
        dismiss()
    }
}
