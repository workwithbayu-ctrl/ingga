import SwiftUI
import SwiftData

struct PocketListView: View {
    @Query(sort: \Pocket.createdAt, order: .reverse) private var pockets: [Pocket]
    @Query private var wallets: [Wallet]
    @Environment(\.modelContext) private var modelContext
    @State private var showAddPocket = false
    @State private var selectedPocket: Pocket?

    var body: some View {
        ZStack {
            // Dark background sesuai tema aplikasi
            Color(hex: "0B1220")?.ignoresSafeArea() ?? Color.black.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Header
                    HStack {
                        Text("Pocket Saya")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: { showAddPocket = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    if pockets.isEmpty {
                        EmptyPocketView()
                    } else {
                        ForEach(pockets) { pocket in
                            Button(action: {
                                selectedPocket = pocket
                            }) {
                                PocketCard(pocket: pocket, wallets: wallets)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $showAddPocket) {
            AddPocketView()
        }
        .sheet(item: $selectedPocket) { pocket in
            NavigationStack {
                PocketDetailView(pocket: pocket)
            }
        }
    }
}

struct PocketCard: View {
    let pocket: Pocket
    let wallets: [Wallet]

    var walletName: String {
        if let walletID = pocket.walletID,
           let wallet = wallets.first(where: { $0.id == walletID }) {
            return wallet.name
        }
        return "Tidak terhubung"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color(hex: pocket.colorHex) ?? .blue)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: pocket.icon)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(pocket.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Text(walletName)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Rp \(formattedAmount(pocket.balance))")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Text("/ Rp \(formattedAmount(pocket.targetAmount))")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: pocket.colorHex) ?? .blue)
                        .frame(width: geo.size.width * CGFloat(pocket.progress), height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text(pocket.formattedProgress)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Text("Alokasi: \(Int(pocket.allocationPercentage))%")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "2C5282") ?? Color.blue,
                    Color(hex: "0B1220") ?? Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
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

struct EmptyPocketView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "archivebox")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.3))

            Text("Belum ada Pocket")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))

            Text("Buat pocket untuk menabung target finansialmu")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}
