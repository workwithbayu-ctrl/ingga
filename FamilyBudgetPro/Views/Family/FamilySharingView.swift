import SwiftUI
import SwiftData
import FirebaseAuth

struct FamilySharingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var familyService = FamilyService.shared
    

    @State private var showCreateSheet = false
    @State private var showJoinSheet = false
    @State private var showLeaveAlert = false
    @State private var familyName = ""
    @State private var joinCode = ""
    @State private var showCopiedToast = false

    var body: some View {
        ZStack {
            (Color(hex: "#0B1220") ?? Color.gray)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    if familyService.hasFamily {
                        // Show family info
                        familyInfoSection
                        membersSection
                        actionsSection
                    } else {
                        // Show create/join options
                        noFamilySection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationTitle("Berbagi Keluarga")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(hex: "#0B1220") ?? Color.gray, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .overlay {
            if familyService.isLoading {
                LoadingOverlay(message: "Memproses...")
            }
        }
        .alert("Keluar Keluarga", isPresented: $showLeaveAlert) {
            Button("Batal", role: .cancel) {}
            Button("Keluar", role: .destructive) {
                Task {
                    await familyService.leaveFamily(modelContext: modelContext)
                }
            }
        } message: {
            Text("Anda akan keluar dari keluarga ini. Data yang sudah tersinkron akan tetap ada di perangkat Anda.")
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateFamilySheet(familyName: $familyName) {
                Task {
                    await familyService.createFamily(name: familyName, modelContext: modelContext)
                    if familyService.successMessage != nil {
                        showCreateSheet = false
                        familyName = ""
                    }
                }
            }
        }
        .sheet(isPresented: $showJoinSheet) {
            JoinFamilySheet(joinCode: $joinCode) {
                Task {
                    await familyService.joinFamily(code: joinCode, modelContext: modelContext)
                    if familyService.successMessage != nil {
                        showJoinSheet = false
                        joinCode = ""
                    }
                }
            }
        }
        .onAppear {
            Task {
                await familyService.checkCurrentFamily(modelContext: modelContext)
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: familyService.hasFamily ? "person.3.fill" : "person.3")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: familyService.hasFamily ? [.cyan, .blue] : [.gray.opacity(0.5), .gray.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(familyService.hasFamily ? familyService.currentFamily?.name ?? "Keluarga" : "Belum Ada Keluarga")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)

            if familyService.hasFamily, let code = familyService.currentFamily?.familyCode {
                HStack(spacing: 8) {
                    Text("Kode: \(code)")
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundColor(.cyan)

                    Button {
                        UIPasteboard.general.string = familyService.shareFamilyCode()
                        withAnimation {
                            showCopiedToast = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showCopiedToast = false
                            }
                        }
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.cyan)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.cyan.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .overlay(alignment: .bottom) {
            if showCopiedToast {
                Text("Tersalin!")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.8))
                    .cornerRadius(8)
                    .offset(y: 30)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - No Family Section
    private var noFamilySection: some View {
        VStack(spacing: 16) {
            Text("Bagikan data keuangan dengan pasangan atau anggota keluarga Anda secara real-time.")
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 12) {
                Button {
                    showCreateSheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Buat Keluarga Baru")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }

                Button {
                    showJoinSheet = true
                } label: {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Gabung Keluarga")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.cyan)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.cyan.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(16)
                }
            }
        }
    }

    // MARK: - Family Info Section
    private var familyInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.cyan)
                Text("Informasi Keluarga")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                FamilyInfoRow(label: "Dibuat oleh", value: familyService.currentFamily?.createdBy ?? "-")
                FamilyInfoRow(label: "Tanggal dibuat", value: formatDate(familyService.currentFamily?.createdAt))
                FamilyInfoRow(label: "Jumlah anggota", value: "\(familyService.familyMembers.count) orang")
                FamilyInfoRow(label: "Status", value: familyService.currentFamily?.isActive == true ? "Aktif" : "Nonaktif")
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }

    // MARK: - Members Section
    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.cyan)
                Text("Anggota Keluarga")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()

                Text("\(familyService.familyMembers.count)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
            }

            ForEach(familyService.familyMembers) { member in
                MemberRow(member: member, isCurrentUser: member.id == Auth.auth().currentUser?.uid)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }

    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button {
                let activityVC = UIActivityViewController(
                    activityItems: [familyService.shareFamilyCode()],
                    applicationActivities: nil
                )
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    rootVC.present(activityVC, animated: true)
                }
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Bagikan Kode Keluarga")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.green.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(16)
            }

            Button {
                showLeaveAlert = true
            } label: {
                HStack {
                    Image(systemName: "person.badge.minus")
                    Text("Keluar dari Keluarga")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(16)
            }
        }
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "-" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "id_ID")
        return formatter.string(from: date)
    }
}

// MARK: - Member Row
struct MemberRow: View {
    let member: FamilyMember
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill((Color(hex: member.avatarColor) ?? Color.blue).opacity(0.2))
                    .frame(width: 44, height: 44)

                Text(String(member.name.prefix(1)).uppercased())
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: member.avatarColor) ?? Color.blue)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(member.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)

                    if isCurrentUser {
                        Text("Anda")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.cyan)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.cyan.opacity(0.15))
                            .cornerRadius(6)
                    }
                }

                Text(member.email)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }

            Spacer()

            // Role badge
            HStack(spacing: 4) {
                Image(systemName: member.role.icon)
                    .font(.system(size: 10))
                Text(member.role.displayName)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(roleColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(roleColor.opacity(0.15))
            .cornerRadius(8)
        }
        .padding(.vertical, 8)
    }

    private var roleColor: Color {
        switch member.role {
        case .owner: return .yellow
        case .admin: return .orange
        case .member: return .gray
        }
    }
}

// MARK: - Info Row
struct FamilyInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Create Family Sheet
struct CreateFamilySheet: View {
    @Binding var familyName: String
    let onCreate: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                (Color(hex: "#0B1220") ?? Color.gray)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom))

                    Text("Buat Keluarga Baru")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)

                    Text("Buat grup keluarga untuk berbagi data keuangan dengan pasangan atau anggota keluarga.")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nama Keluarga")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)

                        TextField("Contoh: Keluarga Pralingga", text: $familyName)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                            )
                    }

                    Spacer()

                    Button {
                        onCreate()
                    } label: {
                        Text("Buat Keluarga")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                familyName.isEmpty ? Color.gray.opacity(0.3) : Color.cyan
                            )
                            .cornerRadius(16)
                    }
                    .disabled(familyName.isEmpty)
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Batal") { dismiss() }
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

// MARK: - Join Family Sheet
struct JoinFamilySheet: View {
    @Binding var joinCode: String
    let onJoin: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                (Color(hex: "#0B1220") ?? Color.gray)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Image(systemName: "person.badge.key.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom))

                    Text("Gabung Keluarga")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)

                    Text("Masukkan kode keluarga 6 digit yang diberikan oleh pemilik keluarga.")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Kode Keluarga")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)

                        TextField("ABC123", text: $joinCode)
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .textInputAutocapitalization(.characters)
                            .keyboardType(.asciiCapable)
                            .limitText($joinCode, to: 6)
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                            )
                    }

                    Spacer()

                    Button {
                        onJoin()
                    } label: {
                        Text("Gabung")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                joinCode.count < 6 ? Color.gray.opacity(0.3) : Color.cyan
                            )
                            .cornerRadius(16)
                    }
                    .disabled(joinCode.count < 6)
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Batal") { dismiss() }
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

// MARK: - Loading Overlay
struct LoadingOverlay: View {
    let message: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.cyan)
                Text(message)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(Color(hex: "#1A2332") ?? Color.gray)
            .cornerRadius(16)
        }
    }
}

// MARK: - Text Field Limit Modifier
extension View {
    func limitText(_ text: Binding<String>, to characterLimit: Int) -> some View {
        self.onChange(of: text.wrappedValue) { oldValue, newValue in
            if newValue.count > characterLimit {
                text.wrappedValue = String(newValue.prefix(characterLimit))
            }
        }
    }
}
