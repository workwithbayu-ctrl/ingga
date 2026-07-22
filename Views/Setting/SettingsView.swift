// SettingsView.swift
// Views/Setting/SettingsView.swift

import SwiftUI
import SwiftData
import FirebaseAuth
import FirebaseFirestore

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var dataService: DataService
    @StateObject private var authService = AuthService.shared
    @StateObject private var familyService = FamilyService.shared

    var onLogout: (() -> Void)? = nil

    // Profile states
    @State private var currentUserProfile: UserProfile?
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var photoURL: String? = nil
    @State private var authProvider: String = ""

    // Password change states
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmNewPassword: String = ""
    @State private var showPasswordSection: Bool = false

    // Toggle states
    @State private var rememberMe: Bool = true
    @State private var biometricEnabled: Bool = false
    @State private var autoSync: Bool = true

    // UI states
    @State private var showSuccessToast: Bool = false
    @State private var successMessage: String = ""
    @State private var showErrorToast: Bool = false
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false
    @State private var showLogoutConfirm: Bool = false
    @State private var showSyncStatus: Bool = false
    @State private var lastSyncDate: Date? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                (Color(hex: "0B1220") ?? Color.black)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Profile Header
                        profileHeader

                        // Account Info Section
                        settingsSection(title: "Akun") {
                            VStack(spacing: 16) {
                                CustomSettingsField(icon: "person.fill", title: "Nama", text: $name)
                                CustomSettingsField(icon: "envelope.fill", title: "Email", text: $email, isEmail: true, isReadOnly: true)

                                // Auth Provider Badge
                                HStack {
                                    Image(systemName: authProvider == "google" ? "globe" : "envelope.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "64B4FF") ?? Color.blue)
                                    Text("Login via \(authProvider.capitalized)")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(hex: "8B9BB4") ?? Color.gray)
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white.opacity(0.03))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color(hex: "64B4FF") ?? Color.blue.opacity(0.1), lineWidth: 1)
                                        )
                                )

                                Button(action: saveProfile) {
                                    HStack {
                                        Spacer()
                                        if isLoading {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        } else {
                                            Text("Simpan Perubahan")
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(.white)
                                        }
                                        Spacer()
                                    }
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color(hex: "64B4FF") ?? Color.blue, Color(hex: "3C8CDC") ?? Color.blue],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    )
                                }
                                .disabled(isLoading)
                            }
                        }

                        // Sync Status Section
                        settingsSection(title: "Sinkronisasi") {
                            VStack(spacing: 0) {
                                // Auto Sync Toggle
                                ToggleRow(
                                    icon: "arrow.triangle.2.circlepath",
                                    title: "Auto Sync",
                                    subtitle: "Sinkron otomatis ke cloud",
                                    isOn: $autoSync
                                )
                                .onChange(of: autoSync) { _, newValue in
                                    if newValue {
                                        FirebaseSyncService.shared.startAutoSync(modelContext: modelContext)
                                        showSuccess("Auto sync diaktifkan")
                                    } else {
                                        FirebaseSyncService.shared.stopAutoSync()
                                        showSuccess("Auto sync dimatikan")
                                    }
                                }

                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.vertical, 8)

                                // Last Sync Info
                                HStack(spacing: 12) {
                                    Image(systemName: "clock")
                                        .font(.system(size: 18))
                                        .foregroundColor(Color(hex: "64B4FF") ?? Color.blue)
                                        .frame(width: 28)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Sync Terakhir")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)

                                        Text(lastSyncDate != nil ? lastSyncDate!.formatted(date: .abbreviated, time: .shortened) : "Belum pernah sync")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color(hex: "8B9BB4") ?? Color.gray)
                                    }

                                    Spacer()

                                    // Firebase connection status
                                    Circle()
                                        .fill(Auth.auth().currentUser != nil ? Color.green : Color.orange)
                                        .frame(width: 8, height: 8)
                                }
                                .padding(.vertical, 6)

                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.vertical, 8)

                                // Manual Sync Button
                                Button(action: manualSync) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "arrow.up.arrow.down")
                                            .font(.system(size: 16))
                                            .foregroundColor(Color(hex: "64B4FF") ?? Color.blue)

                                        Text("Sync Sekarang")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.white)

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color(hex: "8B9BB4") ?? Color.gray)
                                    }
                                    .padding(.vertical, 10)
                                }
                                .buttonStyle(.plain)
                            }
                        }


                        // Family Sharing Section
                        settingsSection(title: "Keluarga") {
                            VStack(spacing: 0) {
                                NavigationLink(destination: FamilySharingView()) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "person.3.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(Color(hex: "64B4FF") ?? Color.blue)
                                            .frame(width: 28)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Berbagi Keluarga")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white)

                                            Text(FamilyService.shared.hasFamily
                                                ? (FamilyService.shared.currentFamily?.name ?? "Kelola keluarga")
                                                : "Bagikan data dengan keluarga")
                                                .font(.system(size: 12))
                                                .foregroundColor(Color(hex: "8B9BB4") ?? Color.gray)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color(hex: "8B9BB4") ?? Color.gray)
                                    }
                                    .padding(.vertical, 10)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        // Security Section
                        settingsSection(title: "Keamanan") {
                            VStack(spacing: 0) {
                                // Change Password Toggle (hanya untuk email auth)
                                if authProvider != "google" {
                                    Button(action: { withAnimation { showPasswordSection.toggle() } }) {
                                        HStack {
                                            Image(systemName: "lock.shield")
                                                .font(.system(size: 18))
                                                .foregroundColor(Color(hex: "64B4FF") ?? Color.blue)
                                                .frame(width: 28)

                                            Text("Ubah Password")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white)

                                            Spacer()

                                            Image(systemName: showPasswordSection ? "chevron.up" : "chevron.down")
                                                .font(.system(size: 14))
                                                .foregroundColor(Color(hex: "8B9BB4") ?? Color.gray)
                                        }
                                        .padding(.vertical, 14)
                                    }
                                    .buttonStyle(.plain)

                                    if showPasswordSection {
                                        VStack(spacing: 12) {
                                            CustomSecureField(
                                                placeholder: "Password Saat Ini",
                                                text: $currentPassword
                                            )

                                            CustomSecureField(
                                                placeholder: "Password Baru",
                                                text: $newPassword
                                            )

                                            CustomSecureField(
                                                placeholder: "Konfirmasi Password Baru",
                                                text: $confirmNewPassword
                                            )

                                            Button(action: changePassword) {
                                                HStack {
                                                    Spacer()
                                                    Text("Update Password")
                                                        .font(.system(size: 15, weight: .semibold))
                                                        .foregroundColor(.white)
                                                    Spacer()
                                                }
                                                .padding(.vertical, 14)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(Color(hex: "2C5282") ?? Color.blue)
                                                )
                                            }
                                            .padding(.top, 4)
                                        }
                                        .padding(.top, 8)
                                    }

                                    Divider()
                                        .background(Color.white.opacity(0.1))
                                        .padding(.vertical, 8)
                                }

                                // Remember Me Toggle
                                ToggleRow(
                                    icon: "checkmark.shield",
                                    title: "Ingat Saya",
                                    subtitle: "Tetap login setelah keluar",
                                    isOn: $rememberMe
                                )
                                .onChange(of: rememberMe) { _, newValue in
                                    UserDefaults.standard.set(newValue, forKey: "rememberMe")
                                    UserDefaults.standard.synchronize()
                                    showSuccess("Remember Me \(newValue ? "diaktifkan" : "dimatikan")")
                                }
                            }
                        }

                        // About Section
                        settingsSection(title: "Tentang") {
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 18))
                                        .foregroundColor(Color(hex: "64B4FF") ?? Color.blue)
                                        .frame(width: 28)

                                    Text("Versi")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)

                                    Spacer()

                                    Text("1.0.0")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "8B9BB4") ?? Color.gray)
                                }

                                HStack {
                                    Image(systemName: "shield.checkerboard")
                                        .font(.system(size: 18))
                                        .foregroundColor(Color(hex: "64B4FF") ?? Color.blue)
                                        .frame(width: 28)

                                    Text("FamilyBudgetPro")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)

                                    Spacer()

                                    Text("Your Family's Financial Guardian")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "8B9BB4") ?? Color.gray)
                                }
                            }
                        }

                        // Logout Button
                        Button(action: { showLogoutConfirm = true }) {
                            HStack {
                                Spacer()
                                Image(systemName: "arrow.right.square")
                                    .font(.system(size: 16))
                                Text("Keluar")
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                            }
                            .foregroundColor(.red)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                        .alert("Keluar", isPresented: $showLogoutConfirm) {
                            Button("Batal", role: .cancel) { }
                            Button("Keluar", role: .destructive) {
                                performLogout()
                            }
                        } message: {
                            Text("Apakah Anda yakin ingin keluar? Data lokal tetap tersimpan.")
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }

                // Success Toast
                if showSuccessToast {
                    VStack {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(successMessage)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "1A1F3A") ?? Color.black)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 24)
                        .padding(.top, 60)
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Error Toast
                if showErrorToast {
                    VStack {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(errorMessage)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "1A1F3A") ?? Color.black)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 24)
                        .padding(.top, 60)
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .navigationTitle("Pengaturan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "8B9BB4") ?? Color.gray)
                    }
                }
            }
            .onAppear {
                loadUserData()
                rememberMe = UserDefaults.standard.bool(forKey: "rememberMe")
                biometricEnabled = UserDefaults.standard.bool(forKey: "biometricEnabled")
                autoSync = UserDefaults.standard.object(forKey: "autoSync") as? Bool ?? true
            }
        }
    }

    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "64B4FF") ?? Color.blue.opacity(0.2), Color(hex: "8B5CF6") ?? Color.purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                    .overlay(
                        Circle()
                            .stroke(Color(hex: "64B4FF") ?? Color.blue.opacity(0.5), lineWidth: 2)
                    )

                if let photoURL = photoURL, let url = URL(string: photoURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Text(String(name.prefix(1).uppercased()))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "64B4FF") ?? Color.blue, Color(hex: "8B5CF6") ?? Color.purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .frame(width: 90, height: 90)
                    .clipShape(Circle())
                } else {
                    Text(String(name.prefix(1).uppercased()))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "64B4FF") ?? Color.blue, Color(hex: "8B5CF6") ?? Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }

            Text(name.isEmpty ? "User" : name)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(email.isEmpty ? "No email" : email)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "8B9BB4") ?? Color.gray)
        }
        .padding(.vertical, 24)
    }

    // MARK: - Settings Section
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "8B9BB4") ?? Color.gray)
                .tracking(1)
                .textCase(.uppercase)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "64B4FF") ?? Color.blue.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Data Loading
    private func loadUserData() {
        // Load from UserProfile (Firebase auth)
        let profileDescriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { $0.isLoggedIn == true }
        )

        if let profile = try? modelContext.fetch(profileDescriptor).first {
            currentUserProfile = profile
            name = profile.displayName
            email = profile.email
            photoURL = profile.photoURL
            authProvider = profile.authProvider
            lastSyncDate = profile.lastSyncAt
            print("SettingsView - Loaded UserProfile: \(profile.displayName)")
        } else {
            // Fallback: load from legacy User model
            let userDescriptor = FetchDescriptor<User>()
            if let user = try? modelContext.fetch(userDescriptor).first {
                name = user.name
                email = user.email
                authProvider = "email"
                print("SettingsView - Loaded legacy User: \(user.name)")
            } else {
                print("SettingsView - No user found!")
            }
        }
    }

    // MARK: - Save Profile
    private func saveProfile() {
        guard !name.isEmpty else {
            showError("Nama tidak boleh kosong")
            return
        }

        isLoading = true

        Task {
            // Update Firebase profile
            if let firebaseUser = Auth.auth().currentUser {
                let changeRequest = firebaseUser.createProfileChangeRequest()
                changeRequest.displayName = name
                try? await changeRequest.commitChanges()

                // Update Firestore
                let db = Firestore.firestore()
                try? await db.collection("users").document(firebaseUser.uid).updateData([
                    "displayName": name,
                    "updatedAt": Timestamp(date: Date())
                ])
            }

            // Update local
            await MainActor.run {
                if let profile = currentUserProfile {
                    profile.displayName = name
                    try? modelContext.save()
                }

                // Also update legacy User
                let userDescriptor = FetchDescriptor<User>()
                if let user = try? modelContext.fetch(userDescriptor).first {
                    user.name = name
                    dataService.save()
                }

                isLoading = false
                showSuccess("Profil berhasil diperbarui")
            }
        }
    }

    // MARK: - Change Password
    private func changePassword() {
        guard !currentPassword.isEmpty else {
            showError("Masukkan password saat ini")
            return
        }
        guard !newPassword.isEmpty, newPassword.count >= 6 else {
            showError("Password baru minimal 6 karakter")
            return
        }
        guard newPassword == confirmNewPassword else {
            showError("Password baru tidak cocok")
            return
        }

        isLoading = true

        Task {
            do {
                // Re-authenticate user
                guard let user = Auth.auth().currentUser, let email = user.email else {
                    throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])
                }

                let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
                try await user.reauthenticate(with: credential)

                // Update password
                try await user.updatePassword(to: newPassword)

                await MainActor.run {
                    isLoading = false
                    currentPassword = ""
                    newPassword = ""
                    confirmNewPassword = ""
                    showPasswordSection = false
                    showSuccess("Password berhasil diubah")
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    showError("Gagal mengubah password: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Manual Sync
    private func manualSync() {
        isLoading = true

        Task {
            await FirebaseSyncService.shared.syncAll(modelContext: modelContext)

            await MainActor.run {
                isLoading = false
                lastSyncDate = Date()
                showSuccess("Sinkronisasi berhasil")
            }
        }
    }

    // MARK: - Logout
    private func performLogout() {
        Task {
            await authService.logout(modelContext: modelContext)

            await MainActor.run {
                dismiss()
                onLogout?()
            }
        }
    }

    // MARK: - Toast Helpers
    private func showSuccess(_ message: String) {
        successMessage = message
        withAnimation { showSuccessToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSuccessToast = false }
        }
    }

    private func showError(_ message: String) {
        errorMessage = message
        withAnimation { showErrorToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { showErrorToast = false }
        }
    }
}

// MARK: - Custom Secure Field
struct CustomSecureField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "8B9BB4") ?? Color.gray)
                    .padding(.horizontal, 16)
            }

            SecureField("", text: $text)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "1A1F3A") ?? Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "64B4FF") ?? Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Custom Settings Field
struct CustomSettingsField: View {
    let icon: String
    let title: String
    @Binding var text: String
    var isEmail: Bool = false
    var isReadOnly: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "8B9BB4") ?? Color.gray)

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "64B4FF") ?? Color.blue)
                    .frame(width: 20)

                if isReadOnly {
                    Text(text.isEmpty ? title : text)
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "8B9BB4") ?? Color.gray.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    TextField(title, text: $text)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .keyboardType(isEmail ? .emailAddress : .default)
                        .autocapitalization(.none)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isReadOnly ? Color(hex: "1A1F3A") ?? Color.black.opacity(0.5) : Color(hex: "1A1F3A") ?? Color.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "64B4FF") ?? Color.blue.opacity(isReadOnly ? 0.1 : 0.2), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Toggle Row
struct ToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "64B4FF") ?? Color.blue)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8B9BB4") ?? Color.gray)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "64B4FF") ?? Color.blue))
                .labelsHidden()
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    SettingsView()
        .environmentObject(DataService.shared)
}
