// ContentView.swift
// Views/ContentView.swift

import SwiftUI

// MARK: - Mini BP Logo (for tab bar)
struct MiniBPLogo: View {
    @State private var outerRotation: Double = 0
    @State private var innerRotation: Double = 0

    var body: some View {
        ZStack {
            // Outer dotted ring
            Circle()
                .stroke(
                    (Color(hex: "64B4FF")!).opacity(0.4),
                    style: StrokeStyle(lineWidth: 1, dash: [2, 5])
                )
                .frame(width: 32, height: 32)
                .rotationEffect(.degrees(outerRotation))

            // Inner dotted ring
            Circle()
                .stroke(
                    (Color(hex: "64B4FF")!).opacity(0.2),
                    style: StrokeStyle(lineWidth: 0.5, dash: [1, 4])
                )
                .frame(width: 26, height: 26)
                .rotationEffect(.degrees(innerRotation))

            // BP Text
            HStack(spacing: -1) {
                Text("B")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text("P")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(hex: "64B4FF")!)
            }
        }
        .frame(width: 32, height: 32)
        .onAppear {
            withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
                outerRotation = 360
            }
            withAnimation(.linear(duration: 18).repeatForever(autoreverses: false)) {
                innerRotation = -360
            }
        }
    }
}

struct ContentView: View {
    var onLogout: (() -> Void)? = nil

    @State private var selectedTab: Int = 0
    @State private var showAddMenu: Bool = false
    @State private var showSettings: Bool = false
    @State private var logoutRequested: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent
            customTabBar
        }
        .sheet(isPresented: $showAddMenu) {
            AddTransactionMenuSheet()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(onLogout: {
                print("🚪 SettingsView onLogout triggered")
                logoutRequested = true
                showSettings = false
            })
        }
        // ⭐ FIX: transisi ke LoginView ditentukan oleh KONFIRMASI USER (logoutRequested),
        // bukan oleh berhasil-tidaknya panggilan jaringan Firebase (Auth.auth().signOut()
        // bisa gagal diam-diam kalau ada masalah koneksi/keychain, dan itu tidak boleh
        // mengunci user di dalam app).
        .onChange(of: showSettings) { _, isShown in
            if !isShown && logoutRequested {
                print("🚪 Sheet closed & logout confirmed -> calling onLogout")
                onLogout?()
            }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case 0:
            DashboardView()
        case 1:
            WalletListView()
        case 2:
            CategoryManagementView()
        case 3:
            PocketListView()
        case 4:
            AllTransactionsView()
        default:
            DashboardView()
        }
    }

    private var customTabBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.1))

            // FIX: Top row with Add Button (left) and MiniBP Logo (right) - same size, same row
            HStack {
                // Add Button - seukuran dengan MiniBPLogo (32x32)
                Button(action: { showAddMenu = true }) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "2C5282")!)
                            .frame(width: 32, height: 32)

                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            .frame(width: 32, height: 32)

                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }

                Spacer()

                // AI Assistant Button (MiniBP Logo)
                Button(action: {
                    print("🤖 AI Assistant tapped")
                }) {
                    MiniBPLogo()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)

            // Tab items row - 5 items tanpa FAB di tengah
            HStack(alignment: .bottom, spacing: 0) {
                TabBarItem(
                    icon: "house.fill",
                    label: "Beranda",
                    isSelected: selectedTab == 0,
                    action: { selectedTab = 0 }
                )

                TabBarItem(
                    icon: "wallet.bifold.fill",
                    label: "Dompet",
                    isSelected: selectedTab == 1,
                    action: { selectedTab = 1 }
                )

                TabBarItem(
                    icon: "tag.fill",
                    label: "Kategori",
                    isSelected: selectedTab == 2,
                    action: { selectedTab = 2 }
                )

                TabBarItem(
                    icon: "star.fill",
                    label: "Pocket",
                    isSelected: selectedTab == 3,
                    action: { selectedTab = 3 }
                )

                TabBarItem(
                    icon: "list.bullet",
                    label: "Transaksi",
                    isSelected: selectedTab == 4,
                    action: { selectedTab = 4 }
                )
            }
            .padding(.top, 6)
            .padding(.bottom, 20)
            .background(Color(hex: "0B1220")!)
        }
    }
}

// MARK: - Tab Bar Item
struct TabBarItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    private var activeColor: Color {
        .white
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: isSelected ? 22 : 20))
                    .foregroundColor(isSelected ? activeColor : Color.white.opacity(0.4))

                Text(label)
                    .font(.system(size: 9))
                    .foregroundColor(isSelected ? activeColor : Color.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Add Transaction Menu Sheet
struct AddTransactionMenuSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                (Color(hex: "0B1220")!).ignoresSafeArea()

                VStack(spacing: 0) {
                    closeButton
                    titleText
                    menuButtons
                    Spacer()
                }
            }
        }
    }

    private var closeButton: some View {
        HStack {
            Spacer()
            Button("Tutup") {
                dismiss()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var titleText: some View {
        Text("Tambah Transaksi")
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.white)
            .padding(.top, 24)
            .padding(.bottom, 40)
    }

    private var menuButtons: some View {
        VStack(spacing: 16) {
            MenuRow(
                title: "Pemasukan",
                icon: "arrow.down.circle.fill",
                iconColor: .green,
                destination: AnyView(AddIncomeView())
            )

            MenuRow(
                title: "Pengeluaran",
                icon: "arrow.up.circle.fill",
                iconColor: .red,
                destination: AnyView(AddExpenseView())
            )

            MenuRow(
                title: "Transfer",
                icon: "arrow.left.arrow.right.circle.fill",
                iconColor: .blue,
                destination: AnyView(TransferView())
            )
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Menu Row
    struct MenuRow: View {
        let title: String
        let icon: String
        let iconColor: Color
        let destination: AnyView

        var body: some View {
            NavigationLink(destination: destination) {
                HStack(spacing: 16) {
                    iconView
                    titleText
                    Spacer()
                    chevron
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.08))
                .cornerRadius(16)
            }
        }

        private var iconView: some View {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(iconColor)
            }
        }

        private var titleText: some View {
            Text(title)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white)
        }

        private var chevron: some View {
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
        }
    }
}
