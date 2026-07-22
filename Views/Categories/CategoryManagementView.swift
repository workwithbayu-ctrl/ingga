// CategoryManagementView.swift
// Views/Categories/CategoryManagementView.swift

import SwiftUI
import SwiftData

struct CategoryManagementView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Category.sortOrder) private var allCategories: [Category]

    @State private var selectedType: TransactionType = .expense
    @State private var showingAddIncome = false
    @State private var showingAddExpense = false
    @State private var editingCategory: Category? = nil
    @State private var showingDeleteAlert = false
    @State private var categoryToDelete: Category? = nil
    @State private var expandedParents: Set<UUID> = []
    @State private var hasSeeded = false

    var body: some View {
        ZStack {
            Color(hex: "0B1220")!
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Kategori")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Picker("Tipe", selection: $selectedType) {
                    Text("Pengeluaran").tag(TransactionType.expense)
                    Text("Pemasukan").tag(TransactionType.income)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .tint(Color(hex: "64B4FF")!)

                if selectedType == .income {
                    incomeListView
                } else {
                    expenseListView
                }
            }
        }
        .task {
            await seedCategoriesIfNeeded()
        }
        .sheet(item: $editingCategory) { category in
            EditIncomeCategoryView(category: category)
        }
        .sheet(isPresented: $showingAddIncome) {
            AddIncomeCategoryView()
        }
        .sheet(isPresented: $showingAddExpense) {
            CategoryFormView(defaultType: .expense)
        }
        .alert("Hapus Kategori?", isPresented: $showingDeleteAlert) {
            Button("Batal", role: .cancel) {}
            Button("Hapus", role: .destructive) {
                if let cat = categoryToDelete {
                    deleteCategory(cat)
                }
            }
        } message: {
            if let cat = categoryToDelete {
                Text("Kategori '\(cat.name)' akan dihapus. Transaksi terkait tidak akan terhapus.")
            }
        }
    }

    // MARK: - Seeding
    private func seedCategoriesIfNeeded() async {
        guard allCategories.isEmpty, !hasSeeded else { return }
        hasSeeded = true

        var incomeSortOrder = 0
        for item in Category.defaultIncomeCategories {
            let cat = Category(
                name: item.name,
                type: .income,
                icon: item.icon,
                colorHex: item.color,
                isDefault: true,
                isSystem: item.isSystem,
                sortOrder: incomeSortOrder
            )
            modelContext.insert(cat)
            incomeSortOrder += 1
        }

        var expenseSortOrder = 0
        var parentMap: [String: Category] = [:]

        for item in Category.defaultExpenseParents {
            let cat = Category(
                name: item.name,
                type: .expense,
                icon: item.icon,
                colorHex: item.color,
                isDefault: true,
                isSystem: true,
                sortOrder: expenseSortOrder
            )
            modelContext.insert(cat)
            parentMap[item.name] = cat
            expenseSortOrder += 1
        }

        var subSortOrder = 0
        var subMap: [String: Category] = [:]

        for item in Category.defaultExpenseSubcategories {
            if let parent = parentMap[item.parentName] {
                let cat = Category(
                    name: item.name,
                    type: .expense,
                    icon: item.icon,
                    colorHex: item.color,
                    parentCategory: parent,
                    isDefault: true,
                    isSystem: true,
                    sortOrder: subSortOrder
                )
                modelContext.insert(cat)
                subMap[item.name] = cat
                subSortOrder += 1
            }
        }

        if let makeupParent = subMap["Belanja Makeup & Perlengkapan"] {
            let makeupChildren: [(name: String, icon: String, color: String)] = [
                ("Sabun", "bubble.left.fill", "#A8E6CF"),
                ("Handbody", "hand.tap.fill", "#DCEDC1"),
                ("Pasta Gigi", "mouth.fill", "#FFD3B6"),
                ("Lainnya", "ellipsis", "#FFAAA5"),
            ]
            for (index, child) in makeupChildren.enumerated() {
                let cat = Category(
                    name: child.name,
                    type: .expense,
                    icon: child.icon,
                    colorHex: child.color,
                    parentCategory: makeupParent,
                    isDefault: true,
                    isSystem: true,
                    sortOrder: index
                )
                modelContext.insert(cat)
            }
        }

        try? modelContext.save()
    }

    // MARK: - Expense List
    private var expenseListView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                ForEach(expenseParentCategories) { parent in
                    expenseParentCard(parent)
                }

                Button {
                    showingAddExpense = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text("Tambah Kategori")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(Color(hex: "64B4FF")!)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "64B4FF")!.opacity(0.4), lineWidth: 1.5)
                            .background(
                                Color(hex: "64B4FF")!.opacity(0.08)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            )
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }

    private func expenseParentCard(_ parent: Category) -> some View {
        let isExpanded = expandedParents.contains(parent.id)
        let subs = subcategories(of: parent)

        return VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if isExpanded {
                        expandedParents.remove(parent.id)
                    } else {
                        expandedParents.insert(parent.id)
                    }
                }
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: parent.colorHex)!.opacity(0.2))
                            .frame(width: 44, height: 44)

                        Image(systemName: parent.icon)
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: parent.colorHex)!)
                    }

                    Text(parent.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    Text("\(subs.count) sub")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(subs) { sub in
                        subcategoryRow(sub, parentColor: parent.colorHex)
                    }
                }
                .padding(.top, 4)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private func subcategoryRow(_ sub: Category, parentColor: String) -> some View {
        let childSubs = subcategories(of: sub)
        let hasChildren = !childSubs.isEmpty
        let isChildExpanded = expandedParents.contains(sub.id)

        return VStack(spacing: 0) {
            HStack(spacing: 12) {
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color(hex: parentColor)!.opacity(0.3))
                        .frame(width: 2)
                        .padding(.leading, 22)
                    Spacer()
                }
                .frame(width: 24)

                ZStack {
                    Circle()
                        .fill(Color(hex: sub.colorHex)!.opacity(0.15))
                        .frame(width: 32, height: 32)

                    Image(systemName: sub.icon)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: sub.colorHex)!)
                }

                Text(sub.name)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.9))

                Spacer()

                if hasChildren {
                    Text("\(childSubs.count)")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(6)

                    Image(systemName: isChildExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.03))
            .cornerRadius(12)
            .contentShape(Rectangle())
            .onTapGesture {
                if hasChildren {
                    withAnimation(.spring(response: 0.3)) {
                        if isChildExpanded {
                            expandedParents.remove(sub.id)
                        } else {
                            expandedParents.insert(sub.id)
                        }
                    }
                }
            }

            if hasChildren && isChildExpanded {
                VStack(spacing: 0) {
                    ForEach(childSubs) { child in
                        HStack(spacing: 12) {
                            HStack(spacing: 0) {
                                Rectangle()
                                    .fill(Color(hex: parentColor)!.opacity(0.15))
                                    .frame(width: 2)
                                    .padding(.leading, 46)
                                Spacer()
                            }
                            .frame(width: 48)

                            ZStack {
                                Circle()
                                    .fill(Color(hex: child.colorHex)!.opacity(0.1))
                                    .frame(width: 28, height: 28)

                                Image(systemName: child.icon)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: child.colorHex)!)
                            }

                            Text(child.name)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))

                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                }
                .padding(.top, 2)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Income List
    private var incomeListView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                ForEach(incomeCategories) { category in
                    Button {
                        editingCategory = category
                    } label: {
                        incomeRowContent(category)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if !category.isSystem {
                            Button(role: .destructive) {
                                categoryToDelete = category
                                showingDeleteAlert = true
                            } label: {
                                Label("Hapus", systemImage: "trash")
                            }
                        }

                        Button {
                            editingCategory = category
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(Color(hex: "64B4FF")!)
                    }
                }

                Button {
                    showingAddIncome = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text("Tambah Kategori")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(Color(hex: "64B4FF")!)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "64B4FF")!.opacity(0.4), lineWidth: 1.5)
                            .background(
                                Color(hex: "64B4FF")!.opacity(0.08)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            )
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }

    private func incomeRowContent(_ category: Category) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: category.colorHex)!.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: category.icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: category.colorHex)!)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(category.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                if category.isSystem {
                    Text("Default")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            if category.isSystem {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }

    // MARK: - Helpers
    private var expenseParentCategories: [Category] {
        allCategories.filter { $0.type == .expense && $0.parentCategory == nil }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private func subcategories(of parent: Category) -> [Category] {
        guard let subs = parent.subcategories else { return [] }
        return subs.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var incomeCategories: [Category] {
        allCategories.filter { $0.type == .income }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private func deleteCategory(_ category: Category) {
        guard !category.isSystem else { return }
        modelContext.delete(category)
        try? modelContext.save()
    }
}

// MARK: - Add Income Category
// ============================================================
// FIX: Complete rewrite to avoid tap-through bug
// ============================================================
struct AddIncomeCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedIcon = "dollarsign.circle.fill"
    @State private var selectedColor = "34C759"

    let icons = [
        "dollarsign.circle.fill", "briefcase.fill", "laptopcomputer",
        "gift.fill", "chart.line.uptrend.xyaxis", "building.2.fill",
        "person.fill", "star.fill", "trophy.fill", "medal.fill",
        "banknote.fill", "creditcard.fill", "bitcoinsign.circle.fill",
        "arrow.down.circle.fill", "checkmark.seal.fill"
    ]

    let colors = [
        "34C759", "5856D6", "FF9500", "FF3B30", "007AFF",
        "AF52DE", "5AC8FA", "FF2D55", "FFCC00", "00C7BE"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                // Solid background covering entire area
                Color(hex: "0B1220")!
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Nama Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NAMA")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(1)

                            TextField("Nama Kategori", text: $name)
                                .font(.body)
                                .foregroundColor(.white)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.08))
                                )
                        }

                        // Icon Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("IKON")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(1)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 52))], spacing: 10) {
                                ForEach(icons, id: \ .self) { icon in
                                    IconSelectButton(
                                        icon: icon,
                                        isSelected: selectedIcon == icon,
                                        colorHex: selectedColor
                                    ) {
                                        selectedIcon = icon
                                    }
                                }
                            }
                        }

                        // Color Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("WARNA")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(1)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
                                ForEach(colors, id: \ .self) { color in
                                    ColorSelectButton(
                                        colorHex: color,
                                        isSelected: selectedColor == color
                                    ) {
                                        selectedColor = color
                                    }
                                }
                            }
                        }

                        // Preview
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PREVIEW")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(1)

                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: selectedColor)!.opacity(0.2))
                                        .frame(width: 56, height: 56)
                                    Image(systemName: selectedIcon)
                                        .font(.system(size: 24))
                                        .foregroundColor(Color(hex: selectedColor)!)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(name.isEmpty ? "Nama Kategori" : name)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text("Pemasukan")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }

                                Spacer()
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.08))
                            )
                        }

                        // Save Button
                        Button {
                            saveCategory()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                Text("Simpan Kategori")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(name.isEmpty ? Color.white.opacity(0.15) : Color(hex: selectedColor)!)
                            )
                        }
                        .disabled(name.isEmpty)
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Kategori Baru")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .interactiveDismissDisabled()
        }
    }

    private func saveCategory() {
        let maxSort = (try? modelContext.fetch(FetchDescriptor<Category>()).map(\.sortOrder).max()) ?? 0

        let category = Category(
            name: name,
            type: .income,
            icon: selectedIcon,
            colorHex: "#\(selectedColor)",
            isDefault: false,
            isSystem: false,
            sortOrder: maxSort + 1
        )

        modelContext.insert(category)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Icon Select Button
struct IconSelectButton: View {
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

// MARK: - Color Select Button
struct ColorSelectButton: View {
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

// MARK: - Edit Income Category
struct EditIncomeCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let category: Category

    @State private var name: String
    @State private var selectedIcon: String
    @State private var selectedColor: String

    let icons = [
        "dollarsign.circle.fill", "briefcase.fill", "laptopcomputer",
        "gift.fill", "chart.line.uptrend.xyaxis", "building.2.fill",
        "person.fill", "star.fill", "trophy.fill", "medal.fill",
        "banknote.fill", "creditcard.fill", "bitcoinsign.circle.fill",
        "arrow.down.circle.fill", "checkmark.seal.fill"
    ]

    let colors = [
        "34C759", "5856D6", "FF9500", "FF3B30", "007AFF",
        "AF52DE", "5AC8FA", "FF2D55", "FFCC00", "00C7BE"
    ]

    init(category: Category) {
        self.category = category
        _name = State(initialValue: category.name)
        _selectedIcon = State(initialValue: category.icon)
        let cleanColor = category.colorHex.replacingOccurrences(of: "#", with: "")
        _selectedColor = State(initialValue: cleanColor)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0B1220")!
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NAMA")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(1)

                            TextField("Nama Kategori", text: $name)
                                .font(.body)
                                .foregroundColor(.white)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.08))
                                )
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("IKON")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(1)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 52))], spacing: 10) {
                                ForEach(icons, id: \ .self) { icon in
                                    IconSelectButton(
                                        icon: icon,
                                        isSelected: selectedIcon == icon,
                                        colorHex: selectedColor
                                    ) {
                                        selectedIcon = icon
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("WARNA")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(1)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
                                ForEach(colors, id: \ .self) { color in
                                    ColorSelectButton(
                                        colorHex: color,
                                        isSelected: selectedColor == color
                                    ) {
                                        selectedColor = color
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("PREVIEW")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(1)

                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: selectedColor)!.opacity(0.2))
                                        .frame(width: 56, height: 56)
                                    Image(systemName: selectedIcon)
                                        .font(.system(size: 24))
                                        .foregroundColor(Color(hex: selectedColor)!)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(name.isEmpty ? "Nama Kategori" : name)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text("Pemasukan")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }

                                Spacer()
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.08))
                            )
                        }

                        Button {
                            updateCategory()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                Text("Simpan Perubahan")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(name.isEmpty ? Color.white.opacity(0.15) : Color(hex: selectedColor)!)
                            )
                        }
                        .disabled(name.isEmpty)
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Edit Kategori")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .interactiveDismissDisabled()
        }
    }

    private func updateCategory() {
        category.name = name
        category.icon = selectedIcon
        category.colorHex = "#\(selectedColor)"
        try? modelContext.save()
        dismiss()
    }
}
