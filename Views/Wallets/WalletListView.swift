// WalletListView.swift
// Views/Wallets/WalletListView.swift

import SwiftUI
import SwiftData

struct WalletListView: View {
    @Query private var wallets: [Wallet]
    @State private var showAddWallet = false

    private var totalBalance: Double {
        wallets.reduce(0) { $0 + $1.balance }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0B1220")?.ignoresSafeArea() ?? Color.black.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Total Balance Card
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Total Saldo Dompet")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))

                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                Text("Rp")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))

                                Text(formattedAmount(totalBalance))
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                            }

                            Text("\(wallets.count) rekening")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "2C5282") ?? Color.blue,
                                    Color(hex: "0B1220") ?? Color.black
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(28)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(.white.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)

                        // Wallet List
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Rekening Saya")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                                .padding(.bottom, 12)

                            if wallets.isEmpty {
                                Text("Belum ada rekening")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.5))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 32)
                            } else {
                                VStack(spacing: 0) {
                                    // FIX: Use \.element.id (with backslash)
                                    ForEach(Array(wallets.enumerated()), id: \.element.id) { index, wallet in
                                        WalletRowDark(wallet: wallet)

                                        if index < wallets.count - 1 {
                                            Divider()
                                                .background(Color.white.opacity(0.1))
                                                .padding(.leading, 72)
                                        }
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.bottom, 12)
                            }
                        }
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "2C5282") ?? Color.blue,
                                    Color(hex: "0B1220") ?? Color.black
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(28)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(.white.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Dompet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAddWallet = true }) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "2C5282") ?? Color.blue)
                                .frame(width: 36, height: 36)
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddWallet) {
                AddWalletView()
            }
        }
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

struct WalletRowDark: View {
    let wallet: Wallet

    private var walletEmoji: String {
        let map: [String: String] = [
            "banknote.fill": "💵",
            "building.columns.fill": "🏛️",
            "creditcard.fill": "💳",
            "iphone": "📱",
            "wallet.bifold.fill": "👛",
            "dollarsign.circle.fill": "💰"
        ]
        return map[wallet.icon] ?? "💳"
    }

    private var walletTypeText: String {
        switch wallet.walletType {
        case .cash: return "Tunai"
        case .bank: return "Bank"
        case .digital, .ewallet: return "Digital"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 44, height: 44)

                if UIImage(systemName: wallet.icon) != nil {
                    Image(systemName: wallet.icon)
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.9))
                } else {
                    Text(walletEmoji)
                        .font(.system(size: 20))
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(wallet.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)

                // FIX: Remove extra )
                Text(walletTypeText)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            Text("Rp \(formattedAmount(wallet.balance))")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
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
