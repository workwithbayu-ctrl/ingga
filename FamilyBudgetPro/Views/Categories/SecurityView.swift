// SecurityView.swift
// Views/Settings/SecurityView.swift

import SwiftUI

struct SecurityView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var usePIN = true
    @State private var useBiometric = false
    @State private var autoLock = true
    @State private var showPINSetup = false
    @State private var showChangePIN = false

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
                                .fill(Color(hex: "34C759")!.opacity(0.2))
                                .frame(width: 80, height: 80)
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 36))
                                .foregroundColor(Color(hex: "34C759")!)
                        }

                        Text("Keamanan")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)

                        Text("Lindungi data keuangan keluargamu")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 20)

                    // Security Options
                    VStack(spacing: 12) {
                        // PIN Lock
                        SecurityToggleRow(
                            icon: "number.circle.fill",
                            iconColor: "64B4FF",
                            title: "Kunci PIN",
                            subtitle: "Akses app dengan PIN 6 digit",
                            isOn: $usePIN
                        )

                        if usePIN {
                            VStack(spacing: 8) {
                                SecurityActionButton(title: "Ubah PIN", icon: "arrow.clockwise") {
                                    showChangePIN = true
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // Biometric
                        SecurityToggleRow(
                            icon: "faceid",
                            iconColor: "AF52DE",
                            title: "Face ID / Touch ID",
                            subtitle: "Buka kunci dengan biometrik",
                            isOn: $useBiometric
                        )

                        // Auto Lock
                        SecurityToggleRow(
                            icon: "lock.rotation",
                            iconColor: "FF9500",
                            title: "Kunci Otomatis",
                            subtitle: "Kunci app setelah 5 menit tidak aktif",
                            isOn: $autoLock
                        )
                    }
                    .padding(.horizontal, 20)

                    // Data Security Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Keamanan Data")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)

                        VStack(spacing: 8) {
                            InfoRow(icon: "checkmark.shield.fill", title: "Data tersimpan lokal", color: "34C759")
                            InfoRow(icon: "checkmark.shield.fill", title: "Enkripsi AES-256", color: "34C759")
                            InfoRow(icon: "checkmark.shield.fill", title: "Tidak ada data dikirim ke server", color: "34C759")
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 16)

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationTitle("Keamanan")
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
        .sheet(isPresented: $showChangePIN) {
            PINSetupView()
        }
    }
}

// MARK: - Security Toggle Row
struct SecurityToggleRow: View {
    let icon: String
    let iconColor: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: iconColor)!.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: iconColor)!)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(2)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: iconColor)!))
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Security Action Button
struct SecurityActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.08))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let icon: String
    let title: String
    let color: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: color)!)

            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - PIN Setup View (Placeholder)
struct PINSetupView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(hex: "0B1220")!
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Atur PIN Baru")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                Text("Masukkan PIN 6 digit")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))

                // PIN dots placeholder
                HStack(spacing: 16) {
                    ForEach(0..<6) { _ in
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 16, height: 16)
                    }
                }
                .padding(.top, 20)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Batal")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.bottom, 40)
            }
            .padding(.top, 60)
        }
    }
}
