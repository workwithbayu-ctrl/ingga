// ThemeView.swift
// Views/Settings/ThemeView.swift

import SwiftUI

struct ThemeView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedTheme") private var selectedTheme: String = "dark"
    @AppStorage("accentColor") private var accentColor: String = "blue"

    let themes = [
        (id: "dark", name: "Gelap", icon: "moon.fill", color: "2C5282"),
        (id: "light", name: "Terang", icon: "sun.max.fill", color: "FF9500"),
        (id: "auto", name: "Otomatis", icon: "circle.lefthalf.filled", color: "64B4FF")
    ]

    let accentColors = [
        (id: "blue", name: "Biru", hex: "64B4FF"),
        (id: "green", name: "Hijau", hex: "34C759"),
        (id: "purple", name: "Ungu", hex: "AF52DE"),
        (id: "orange", name: "Oranye", hex: "FF9500"),
        (id: "red", name: "Merah", hex: "FF3B30"),
        (id: "pink", name: "Pink", hex: "FF2D55")
    ]

    var body: some View {
        ZStack {
            Color(hex: "0B1220")!
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "AF52DE")!.opacity(0.2))
                                .frame(width: 80, height: 80)
                            Image(systemName: "paintbrush.fill")
                                .font(.system(size: 36))
                                .foregroundColor(Color(hex: "AF52DE")!)
                        }

                        Text("Tema")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)

                        Text("Personalisasi tampilan aplikasi")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 20)

                    // Theme Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Mode Tampilan")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)

                        VStack(spacing: 8) {
                            ForEach(themes, id: \.id) { theme in
                                ThemeOptionRow(
                                    icon: theme.icon,
                                    iconColor: theme.color,
                                    name: theme.name,
                                    isSelected: selectedTheme == theme.id
                                ) {
                                    selectedTheme = theme.id
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Accent Color Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Warna Aksen")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                            ForEach(accentColors, id: \.id) { color in
                                AccentColorOption(
                                    name: color.name,
                                    hex: color.hex,
                                    isSelected: accentColor == color.id
                                ) {
                                    accentColor = color.id
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 8)

                    // Preview Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pratinjau")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)

                        VStack(spacing: 12) {
                            HStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: accentColor == "blue" ? "64B4FF" : accentColors.first(where: { $0.id == accentColor })?.hex ?? "64B4FF")!)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "creditcard.fill")
                                            .foregroundColor(.white)
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Total Saldo")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.6))
                                    Text("Rp 12.500.000")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }

                                Spacer()
                            }
                            .padding(16)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "2C5282")!, Color(hex: "0B1220")!],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 8)

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationTitle("Tema")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Theme Option Row
struct ThemeOptionRow: View {
    let icon: String
    let iconColor: String
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: iconColor)!.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: iconColor)!)
                }

                Text(name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: "34C759")!)
                } else {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color(hex: "34C759")!.opacity(0.5) : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Accent Color Option
struct AccentColorOption: View {
    let name: String
    let hex: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(hex: hex)!)
                        .frame(width: 48, height: 48)

                    if isSelected {
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 56, height: 56)

                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                Text(name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? Color(hex: hex)! : .white.opacity(0.6))
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}
