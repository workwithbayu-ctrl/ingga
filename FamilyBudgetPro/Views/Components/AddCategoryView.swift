import SwiftUI
import SwiftData

struct AddCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var selectedType: TransactionType = .expense
    @State private var selectedIcon: String = "tag.fill"
    @State private var selectedColorHex: String = "64B4FF"
    @State private var isSubcategory: Bool = false
    @State private var selectedParent: Category?
    @State private var isSaving = false
    @State private var showSuccess = false

    @Query private var existingCategories: [Category]

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

    var parentCategories: [Category] {
        existingCategories.filter { $0.parentCategory == nil && $0.type == selectedType }
    }

    var isValid: Bool {
        guard !name.isEmpty else { return false }
        if isSubcategory {
            return selectedParent != nil
        }
        return true
    }

    var body: some View {
        NavigationStack {
            ZStack {
                (Color(hex: "0B1220")!).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Type Toggle
                        typeToggleSection

                        // MARK: - Subcategory Toggle
                        if !parentCategories.isEmpty {
                            subcategoryToggleSection
                        }

                        // MARK: - Parent Selection (if subcategory)
                        if isSubcategory {
                            parentSelectionSection
                        }

                        // MARK: - Name
                        nameSection

                        // MARK: - Icon
                        iconSection

                        // MARK: - Color
                        colorSection

                        // MARK: - Preview
                        previewSection

                        // MARK: - Save Button
                        saveButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }

                if showSuccess {
                    successOverlay
                }
            }
            .navigationTitle("Tambah Kategori")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Batal") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .toolbarBackground(Color(hex: "0B1220")!, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .tint(.white)
    }

    // MARK: - Sections

    private var typeToggleSection: some View {
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
                        isSubcategory = false
                        selectedParent = nil
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

    private var subcategoryToggleSection: some View {
        HStack(spacing: 12) {
            ToggleButtonDark(
                title: "Kategori Utama",
                isSelected: !isSubcategory
            ) {
                withAnimation(.spring(duration: 0.3)) {
                    isSubcategory = false
                    selectedParent = nil
                }
            }

            ToggleButtonDark(
                title: "Sub Kategori",
                isSelected: isSubcategory
            ) {
                withAnimation(.spring(duration: 0.3)) {
                    isSubcategory = true
                }
            }
        }
    }

    private var parentSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("KATEGORI INDUK")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.6))
                .tracking(1)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(parentCategories) { parent in
                        ParentCategoryButtonDark(
                            category: parent,
                            isSelected: selectedParent?.id == parent.id
                        ) {
                            withAnimation(.spring(duration: 0.3)) {
                                selectedParent = parent
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
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

                        if isSubcategory, let parent = selectedParent {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.4))

                            Text("Sub: \(parent.name)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        } else {
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
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)

                    Text("Simpan Kategori")
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
        .padding(.top, 8)
        .padding(.bottom, 40)
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

                Text("Kategori baru telah disimpan")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "1A2A4A")!)
                    .shadow(radius: 20)
            )
        }
    }

    // MARK: - Methods

    private func performSave() {
        guard !name.isEmpty else { return }
        if isSubcategory && selectedParent == nil { return }

        isSaving = true

        let maxSort = (try? modelContext.fetch(FetchDescriptor<Category>()).map(\.sortOrder).max()) ?? 0

        let category = Category(
            name: name,
            type: selectedType,
            icon: selectedIcon,
            colorHex: selectedColorHex,
            parentCategory: isSubcategory ? selectedParent : nil,
            isDefault: false,
            isSystem: false,
            sortOrder: maxSort + 1
        )

        modelContext.insert(category)
        try? modelContext.save()

        withAnimation(.spring(duration: 0.3)) {
            showSuccess = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}

// MARK: - Toggle Button Dark
struct ToggleButtonDark: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color(hex: "2C5282")!.opacity(0.4) : Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? (Color(hex: "64B4FF")!) : Color.clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Parent Category Button Dark
struct ParentCategoryButtonDark: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: category.colorHex)!)

                Text(category.name)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? (Color(hex: category.colorHex)!).opacity(0.2) : Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? (Color(hex: category.colorHex)!) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Type Button Dark
struct TypeButtonDark: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.3) : Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Icon Button Dark
struct IconButtonDark: View {
    let icon: String
    let isSelected: Bool
    let colorHex: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color(hex: colorHex)!.opacity(0.2) : Color.white.opacity(0.06))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Color(hex: colorHex)! : .white.opacity(0.6))
            }
            .overlay(
                Circle()
                    .stroke(isSelected ? Color(hex: colorHex)! : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Color Button Dark
struct ColorButtonDark: View {
    let colorHex: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(hex: colorHex)!)
                    .frame(width: 40, height: 40)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .overlay(
                Circle()
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2.5)
            )
        }
        .buttonStyle(.plain)
    }
}
