import SwiftUI

struct CategoryChip: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.subheadline)
                Text(category.name)
                    .font(.subheadline)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color(hex: category.colorHex) : Color(.systemGray5))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct CategoryGridView: View {
    let categories: [Category]
    @Binding var selectedCategory: Category?
    let columns = [GridItem(.adaptive(minimum: 100), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(categories) { category in
                CategoryChip(
                    category: category,
                    isSelected: selectedCategory?.id == category.id
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedCategory = category
                    }
                }
            }
        }
    }
}

struct CategoryIconButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(hex: category.colorHex)?.opacity(0.15) ?? Color.gray.opacity(0.15))
                        .frame(width: 60, height: 60)

                    Image(systemName: category.icon)
                        .font(.title2)
                        .foregroundStyle(Color(hex: category.colorHex) ?? .gray)
                }
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color(hex: category.colorHex) ?? .blue : Color.clear, lineWidth: 3)
                )

                Text(category.name)
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
