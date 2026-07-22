// LogoutView.swift
// Views/Settings/LogoutView.swift

import SwiftUI
import SwiftData

struct LogoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showLogoutConfirm = false
    @State private var isLoggingOut = false

    var body: some View {
        ZStack {
            Color(hex: "0B1220")!
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Warning Icon
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "FF3B30")!.opacity(0.15))
                            .frame(width: 100, height: 100)

                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(Color(hex: "FF3B30")!)
                    }

                    Text("Keluar dari Akun")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)

                    Text("Apakah kamu yakin ingin keluar? Semua data tetap tersimpan di perangkat ini.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 60)

                Spacer()

                // Action Buttons
                VStack(spacing: 12) {
                    Button {
                        showLogoutConfirm = true
                    } label: {
                        HStack(spacing: 8) {
                            if isLoggingOut {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isLoggingOut ? "Memproses..." : "Ya, Keluar")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "FF3B30")!)
                        .cornerRadius(16)
                    }
                    .disabled(isLoggingOut)

                    Button {
                        dismiss()
                    } label: {
                        Text("Batal")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Keluar")
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
        .alert("Konfirmasi Keluar", isPresented: $showLogoutConfirm) {
            Button("Batal", role: .cancel) { }
            Button("Keluar", role: .destructive) {
                performLogout()
            }
        } message: {
            Text("Semua data lokal akan tetap tersimpan. Kamu bisa masuk kapan saja.")
        }
    }

    private func performLogout() {
        isLoggingOut = true
        Task {
            // ⭐ FIX: sebelumnya ini cuma delay 1.5 detik palsu + dismiss(), tidak pernah
            // benar-benar logout. Sekarang panggil AuthService.shared.logout() yang
            // sesungguhnya — begitu isAuthenticated jadi false, root app
            // (FamilyBudgetProApp.onChange(of: authService.isAuthenticated)) otomatis
            // pindah ke LoginView, tidak peduli seberapa dalam navigasi saat ini.
            await AuthService.shared.logout(modelContext: modelContext)
            await MainActor.run {
                isLoggingOut = false
                dismiss()
            }
        }
    }
}
