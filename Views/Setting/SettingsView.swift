import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataService: DataService

    var onLogout: (() -> Void)? = nil

    // Profile states
    @State private var currentUser: User?
    @State private var name: String = ""
    @State private var email: String = ""

    // Password change states
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmNewPassword: String = ""
    @State private var showPasswordSection: Bool = false

    // Toggle states
    @State private var rememberMe: Bool = true
    @State private var biometricEnabled: Bool = false

    // UI states
    @State private var showSuccessToast: Bool = false
    @State private var successMessage: String = ""
    @State private var showErrorToast: Bool = false
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false
    @State private var showLogoutConfirm: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(hex: "0B1220")!
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Profile Header
                        profileHeader

                        // Profile Section
                        settingsSection(title: "Profile") {
                            VStack(spacing: 16) {
                                CustomSettingsField(icon: "person.fill", title: "Name", text: $name)
                                CustomSettingsField(icon: "envelope.fill", title: "Email", text: $email, isEmail: true, isReadOnly: true)

                                Button(action: saveProfile) {
                                    HStack {
                                        Spacer()
                                        if isLoading {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        } else {
                                            Text("Save Profile")
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
                                                    colors: [Color(hex: "64B4FF")!, Color(hex: "3C8CDC")!],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    )
                                }
                                .disabled(isLoading)
                            }
                        }

                        // Security Section
                        settingsSection(title: "Security") {
                            VStack(spacing: 0) {
                                // Change Password Toggle
                                Button(action: { withAnimation { showPasswordSection.toggle() } }) {
                                    HStack {
                                        Image(systemName: "lock.shield")
                                            .font(.system(size: 18))
                                            .foregroundColor(Color(hex: "64B4FF")!)
                                            .frame(width: 28)

                                        Text("Change Password")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)

                                        Spacer()

                                        Image(systemName: showPasswordSection ? "chevron.up" : "chevron.down")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color(hex: "8B9BB4")!)
                                    }
                                    .padding(.vertical, 14)
                                }
                                .buttonStyle(.plain)

                                if showPasswordSection {
                                    VStack(spacing: 12) {
                                        SecureField("Current Password", text: $currentPassword)
                                            .font(.system(size: 15))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 14)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color(hex: "1A1F3A")!)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(Color(hex: "64B4FF")!.opacity(0.2), lineWidth: 1)
                                                    )
                                            )

                                        SecureField("New Password", text: $newPassword)
                                            .font(.system(size: 15))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 14)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color(hex: "1A1F3A")!)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(Color(hex: "64B4FF")!.opacity(0.2), lineWidth: 1)
                                                    )
                                            )

                                        SecureField("Confirm New Password", text: $confirmNewPassword)
                                            .font(.system(size: 15))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 14)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color(hex: "1A1F3A")!)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(Color(hex: "64B4FF")!.opacity(0.2), lineWidth: 1)
                                                    )
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
                                                    .fill(Color(hex: "2C5282")!)
                                            )
                                        }
                                        .padding(.top, 4)
                                    }
                                    .padding(.top, 8)
                                }

                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.vertical, 8)

                                // Remember Me Toggle
                                ToggleRow(
                                    icon: "checkmark.shield",
                                    title: "Remember Me",
                                    subtitle: "Stay logged in",
                                    isOn: $rememberMe
                                )
                                .onChange(of: rememberMe) { _, newValue in
                                    UserDefaults.standard.set(newValue, forKey: "rememberMe")
                                    UserDefaults.standard.synchronize()
                                    showSuccess("Remember Me \(newValue ? "enabled" : "disabled")")
                                }

                                // Biometric Toggle - disabled (requires NSFaceIDUsageDescription in Info.plist)
                                // Uncomment after adding NSFaceIDUsageDescription to Info.plist
                            }
                        }

                        // About Section
                        settingsSection(title: "About") {
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 18))
                                        .foregroundColor(Color(hex: "64B4FF")!)
                                        .frame(width: 28)

                                    Text("Version")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)

                                    Spacer()

                                    Text("1.0.0")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "8B9BB4")!)
                                }

                                HStack {
                                    Image(systemName: "shield.checkerboard")
                                        .font(.system(size: 18))
                                        .foregroundColor(Color(hex: "64B4FF")!)
                                        .frame(width: 28)

                                    Text("SafeMoney")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)

                                    Spacer()

                                    Text("Your Family's Financial Guardian")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "8B9BB4")!)
                                }
                            }
                        }

                        // Logout Button
                        Button(action: { showLogoutConfirm = true }) {
                            HStack {
                                Spacer()
                                Image(systemName: "arrow.right.square")
                                    .font(.system(size: 16))
                                Text("Logout")
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
                        .alert("Logout", isPresented: $showLogoutConfirm) {
                            Button("Batal", role: .cancel) { }
                            Button("Logout", role: .destructive) {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onLogout?()
                                }
                            }
                        } message: {
                            Text("Apakah Anda yakin ingin keluar?")
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
                                .fill(Color(hex: "1A1F3A")!)
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
                                .fill(Color(hex: "1A1F3A")!)
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
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "8B9BB4")!)
                    }
                }
            }
            .onAppear {
                loadUserData()
                rememberMe = UserDefaults.standard.bool(forKey: "rememberMe")
                biometricEnabled = UserDefaults.standard.bool(forKey: "biometricEnabled")
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
                            colors: [Color(hex: "64B4FF")!.opacity(0.2), Color(hex: "8B5CF6")!.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                    .overlay(
                        Circle()
                            .stroke(Color(hex: "64B4FF")!.opacity(0.5), lineWidth: 2)
                    )

                Text(String(name.prefix(1).uppercased()))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "64B4FF")!, Color(hex: "8B5CF6")!],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text(name.isEmpty ? "User" : name)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(email.isEmpty ? "No email" : email)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "8B9BB4")!)
        }
        .padding(.vertical, 24)
    }

    // MARK: - Settings Section
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "8B9BB4")!)
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
                            .stroke(Color(hex: "64B4FF")!.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Data Loading
    private func loadUserData() {
        let users = dataService.fetchUsers()
        print("📋 SettingsView - Found \(users.count) users")
        for u in users {
            print("   - \(u.name): \(u.email)")
        }

        // Get the first user (or the one matching saved email)
        let savedEmail = UserDefaults.standard.string(forKey: "lastLoggedInEmail") ?? ""
        if let user = users.first(where: { $0.email.lowercased() == savedEmail.lowercased() }) ?? users.first {
            currentUser = user
            name = user.name
            email = user.email
            print("✅ SettingsView - Loaded user: \(user.name) (\(user.email))")
        } else {
            print("❌ SettingsView - No user found!")
        }
    }

    // MARK: - Save Profile
    private func saveProfile() {
        guard !name.isEmpty else {
            showError("Name cannot be empty")
            return
        }
        guard !email.isEmpty, email.contains("@") else {
            showError("Please enter a valid email")
            return
        }

        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let user = currentUser {
                user.name = name
                user.email = email
                dataService.save()
                showSuccess("Profile updated successfully")
            } else {
                showError("User not found")
            }
            isLoading = false
        }
    }

    // MARK: - Change Password
    private func changePassword() {
        print("🔐 changePassword called")

        guard !currentPassword.isEmpty else {
            showError("Please enter current password")
            return
        }
        guard !newPassword.isEmpty, newPassword.count >= 6 else {
            showError("New password must be at least 6 characters")
            return
        }
        guard newPassword == confirmNewPassword else {
            showError("Passwords do not match")
            return
        }

        // Ensure we have a current user
        if currentUser == nil {
            let users = dataService.fetchUsers()
            print("🔐 Looking for user among \(users.count) users")
            currentUser = users.first
        }

        guard let user = currentUser else {
            showError("User not found")
            return
        }

        print("🔐 Checking password for user: \(user.email)")
        print("🔐 Current password entered: \(currentPassword)")
        print("🔐 Stored password: \(user.password)")

        guard user.password == currentPassword else {
            showError("Current password is incorrect")
            return
        }

        user.password = newPassword
        dataService.save()
        print("🔐 Password updated successfully for \(user.email)")

        currentPassword = ""
        newPassword = ""
        confirmNewPassword = ""
        showPasswordSection = false

        showSuccess("Password changed successfully")
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
                .foregroundColor(Color(hex: "8B9BB4")!)

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "64B4FF")!)
                    .frame(width: 20)

                if isReadOnly {
                    Text(text.isEmpty ? title : text)
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "8B9BB4")!.opacity(0.7))
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
                    .fill(isReadOnly ? Color(hex: "1A1F3A")!.opacity(0.5) : Color(hex: "1A1F3A")!)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "64B4FF")!.opacity(isReadOnly ? 0.1 : 0.2), lineWidth: 1)
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
                .foregroundColor(Color(hex: "64B4FF")!)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8B9BB4")!)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "64B4FF")!))
                .labelsHidden()
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    SettingsView()
        .environmentObject(DataService.shared)
}
