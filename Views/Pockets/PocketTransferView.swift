import SwiftUI
import SwiftData

struct PocketTransferView: View {
    @Environment(\.dismiss) private var dismiss
    // FIX: DataService is @Observable, not ObservableObject
    // Use direct access instead of @StateObject

    let sourcePocket: Pocket

    @State private var amount: String = ""
    @State private var selectedDestinationPocket: Pocket?
    @State private var showInsufficientAlert = false

    // ⭐ FIX: Gunakan @Query untuk auto-refresh
    @Query(sort: \Pocket.name) private var allPockets: [Pocket]

    var destinationPockets: [Pocket] {
        allPockets.filter { pocket in
            pocket.id != sourcePocket.id &&
            pocket.walletID == sourcePocket.walletID
        }
    }

    var isValid: Bool {
        let amountValue = Double(amount) ?? 0
        let hasDestination = selectedDestinationPocket != nil
        let hasBalance = amountValue <= sourcePocket.balance
        let isPositive = amountValue > 0
        return isPositive && hasBalance && hasDestination
    }

    var body: some View {
        NavigationStack {
            Form {
                sourceSection
                amountSection
                destinationSection
                summarySection
            }
            .navigationTitle("Transfer Pocket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Transfer") {
                        performTransfer()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
            .alert("Saldo Tidak Cukup", isPresented: $showInsufficientAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Saldo tersedia: \(sourcePocket.balance.formattedCurrency())")
            }
        }
    }

    // MARK: - Sections (dipisah untuk avoid type-check error)

    private var sourceSection: some View {
        Section("Dari Pocket") {
            HStack {
                pocketIcon(sourcePocket)
                Text(sourcePocket.name)
                    .font(.headline)
                Spacer()
                Text(sourcePocket.balance.formattedCurrency())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var amountSection: some View {
        Section("Jumlah") {
            TextField("0", text: $amount)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)

            if let amountValue = Double(amount), amountValue > sourcePocket.balance {
                insufficientLabel
            }
        }
    }

    private var insufficientLabel: some View {
        Label("Saldo tidak cukup", systemImage: "exclamationmark.triangle")
            .foregroundStyle(.orange)
            .font(.caption)
    }

    private var destinationSection: some View {
        Section("Ke Pocket") {
            if destinationPockets.isEmpty {
                emptyDestinationView
            } else {
                destinationList
            }
        }
    }

    private var emptyDestinationView: some View {
        ContentUnavailableView(
            "Tidak Ada Pocket Tujuan",
            systemImage: "arrow.left.arrow.right.circle",
            description: Text("Pocket lain dengan rekening yang sama tidak ditemukan")
        )
    }

    private var destinationList: some View {
        ForEach(destinationPockets) { pocket in
            destinationRow(pocket: pocket)
        }
    }

    private func destinationRow(pocket: Pocket) -> some View {
        Button {
            selectedDestinationPocket = pocket
        } label: {
            HStack {
                pocketIcon(pocket)

                VStack(alignment: .leading) {
                    Text(pocket.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(pocket.balance.formattedCurrency())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected(pocket) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func isSelected(_ pocket: Pocket) -> Bool {
        selectedDestinationPocket?.id == pocket.id
    }

    private func pocketIcon(_ pocket: Pocket) -> some View {
        Image(systemName: pocket.icon)
            .foregroundStyle(Color(hex: pocket.colorHex) ?? .gray)
    }

    private var summarySection: some View {
        Group {
            if let dest = selectedDestinationPocket,
               let amountValue = Double(amount),
               amountValue > 0 {
                Section("Ringkasan") {
                    summaryContent(amount: amountValue, destination: dest)
                }
            }
        }
    }

    private func summaryContent(amount: Double, destination: Pocket) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(sourcePocket.name)
                Spacer()
                Text("-\(amount.formattedCurrency())")
                    .foregroundStyle(.red)
            }

            HStack {
                Text(destination.name)
                Spacer()
                Text("+\(amount.formattedCurrency())")
                    .foregroundStyle(.green)
            }
        }
    }

    // MARK: - Actions

    private func performTransfer() {
        guard let destination = selectedDestinationPocket,
              let amountValue = Double(amount),
              amountValue > 0,
              amountValue <= sourcePocket.balance else {
            return
        }

        // FIX: Use DataService.shared directly
        DataService.shared.transferBetweenPockets(
            from: sourcePocket,
            to: destination,
            amount: amountValue,
            note: "Transfer antar pocket",
            date: Date()
        )

        dismiss()
    }
}
