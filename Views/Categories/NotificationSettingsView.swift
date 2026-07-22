// NotificationSettingsView.swift
// Views/Categories/NotificationSettingsView.swift

import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var dailyReminder = true
    @State private var weeklyReport = true
    @State private var budgetAlert = true
    @State private var transactionAlert = false
    @State private var pocketGoalAlert = true
    @State private var reminderTime = Date()

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
                                .fill(Color(hex: "FF9500")!.opacity(0.2))
                                .frame(width: 80, height: 80)
                            Image(systemName: "bell.fill")
                                .font(.system(size: 36))
                                .foregroundColor(Color(hex: "FF9500")!)
                        }

                        Text("Atur Notifikasi")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)

                        Text("Pilih notifikasi yang ingin kamu terima")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // Toggle Items
                    VStack(spacing: 12) {
                        NotificationToggleRow(
                            icon: "clock.fill",
                            iconColor: "64B4FF",
                            title: "Pengingat Harian",
                            subtitle: "Ingatkan untuk mencatat transaksi",
                            isOn: $dailyReminder
                        )

                        if dailyReminder {
                            HStack {
                                Spacer()
                                DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.compact)
                                    .colorMultiply(.blue)
                                    .labelsHidden()
                                    .frame(width: 100)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)
                        }

                        NotificationToggleRow(
                            icon: "chart.bar.fill",
                            iconColor: "34C759",
                            title: "Laporan Mingguan",
                            subtitle: "Ringkasan pengeluaran setiap minggu",
                            isOn: $weeklyReport
                        )

                        NotificationToggleRow(
                            icon: "exclamationmark.triangle.fill",
                            iconColor: "FF3B30",
                            title: "Peringatan Budget",
                            subtitle: "Notifikasi saat mendekati batas budget",
                            isOn: $budgetAlert
                        )

                        NotificationToggleRow(
                            icon: "arrow.left.arrow.right",
                            iconColor: "AF52DE",
                            title: "Notifikasi Transaksi",
                            subtitle: "Notifikasi setiap ada transaksi baru",
                            isOn: $transactionAlert
                        )

                        NotificationToggleRow(
                            icon: "target",
                            iconColor: "FF9500",
                            title: "Target Pocket",
                            subtitle: "Notifikasi saat pocket mencapai target",
                            isOn: $pocketGoalAlert
                        )
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationTitle("Notifikasi")
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

// MARK: - Notification Toggle Row
struct NotificationToggleRow: View {
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
                    .lineLimit(1)
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
