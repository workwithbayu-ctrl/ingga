// HelpView.swift
// Views/Categories/HelpView.swift

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var expandedFAQ: UUID? = nil

    let faqs = [
        FAQItem(question: "Bagaimana cara menambah transaksi?", answer: "Buka tab Transaksi, lalu tap tombol + di pojok kanan atas. Pilih jenis transaksi (Pemasukan/Pengeluaran), masukkan jumlah, pilih kategori, dan simpan."),
        FAQItem(question: "Apa itu Pocket Tabungan?", answer: "Pocket adalah fitur untuk menyisihkan uang dari dompet ke tabungan tujuan tertentu. Kamu bisa buat pocket untuk dana darurat, liburan, atau tujuan lain."),
        FAQItem(question: "Bagaimana cara transfer antar dompet?", answer: "Buka tab Dompet, pilih dompet sumber, lalu pilih opsi Transfer. Pilih dompet tujuan dan masukkan jumlah yang ingin ditransfer."),
        FAQItem(question: "Apakah data saya aman?", answer: "Ya, semua data tersimpan secara lokal di perangkatmu dengan enkripsi AES-256. Tidak ada data yang dikirim ke server eksternal."),
        FAQItem(question: "Bagaimana cara backup data?", answer: "Saat ini backup dilakukan secara otomatis melalui iCloud. Kamu juga bisa export data ke CSV melalui menu Pengaturan > Keamanan."),
        FAQItem(question: "Bisa digunakan berapa anggota keluarga?", answer: "FamilyBudgetPro mendukung hingga 5 anggota keluarga dengan 1 akun admin dan 4 akun anggota."),
        FAQItem(question: "Bagaimana cara mengatur budget bulanan?", answer: "Buka tab Analisis, pilih periode bulanan, lalu tap tombol Atur Budget. Masukkan batas pengeluaran untuk setiap kategori."),
        FAQItem(question: "Apakah ada notifikasi pengingat?", answer: "Ya, kamu bisa aktifkan pengingat harian melalui menu Pengaturan > Notifikasi."),
    ]

    var filteredFAQs: [FAQItem] {
        if searchText.isEmpty {
            return faqs
        }
        return faqs.filter { item in
            let qMatch = item.question.localizedCaseInsensitiveContains(searchText)
            let aMatch = item.answer.localizedCaseInsensitiveContains(searchText)
            return qMatch || aMatch
        }
    }

    var body: some View {
        ZStack {
            Color(hex: "0B1220")!
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerView
                    searchBarView
                    supportButtonView
                    faqSectionView
                    appInfoView
                }
            }
        }
        .navigationTitle("Bantuan")
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

    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "5AC8FA")!.opacity(0.2))
                    .frame(width: 80, height: 80)
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(Color(hex: "5AC8FA")!)
            }

            Text("Bantuan")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            Text("Temukan jawaban untuk pertanyaanmu")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.top, 20)
    }

    // MARK: - Search Bar
    private var searchBarView: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.5))

            TextField("Cari pertanyaan...", text: $searchText)
                .font(.system(size: 15))
                .foregroundColor(.white)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Support Button
    private var supportButtonView: some View {
        Button {
            // Open support
        } label: {
            supportButtonContent
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }

    private var supportButtonContent: some View {
        HStack(spacing: 14) {
            supportIconView
            supportTextView
            Spacer()
            chevronView
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

    private var supportIconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "34C759")!.opacity(0.2))
                .frame(width: 44, height: 44)
            Image(systemName: "message.fill")
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "34C759")!)
        }
    }

    private var supportTextView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Hubungi Dukungan")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            Text("Email ke support@familybudget.id")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    private var chevronView: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 14))
            .foregroundColor(.white.opacity(0.3))
    }

    // MARK: - FAQ Section
    private var faqSectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pertanyaan Umum")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)

            VStack(spacing: 8) {
                ForEach(filteredFAQs) { faq in
                    FAQRow(
                        item: faq,
                        isExpanded: expandedFAQ == faq.id
                    ) {
                        toggleFAQ(faq.id)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func toggleFAQ(_ id: UUID) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedFAQ == id {
                expandedFAQ = nil
            } else {
                expandedFAQ = id
            }
        }
    }

    // MARK: - App Info
    private var appInfoView: some View {
        VStack(spacing: 8) {
            Text("FamilyBudgetPro")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            Text("Versi 1.0.0 (Build 24)")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.top, 20)
        .padding(.bottom, 30)
    }
}

// MARK: - FAQ Item
struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

// MARK: - FAQ Row
struct FAQRow: View {
    let item: FAQItem
    let isExpanded: Bool
    let action: () -> Void

    private var borderColor: Color {
        if isExpanded {
            return Color(hex: "5AC8FA")!.opacity(0.3)
        }
        return Color.white.opacity(0.1)
    }

    private var borderWidth: CGFloat {
        if isExpanded {
            return 1.5
        }
        return 1.0
    }

    var body: some View {
        Button(action: action) {
            faqContent
        }
        .buttonStyle(.plain)
    }

    private var faqContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            questionRow
            if isExpanded {
                answerSection
            }
        }
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: borderWidth)
        )
    }

    private var questionRow: some View {
        HStack(spacing: 12) {
            Text(item.question)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)

            Spacer()

            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var answerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.horizontal, 16)

            Text(item.answer)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
    }
}
