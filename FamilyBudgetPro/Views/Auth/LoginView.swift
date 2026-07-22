import SwiftUI
import UIKit
import LocalAuthentication
import SwiftData
import FirebaseAuth
import GoogleSignIn

// MARK: - Floating Particle
struct LoginParticle: View {
    let size: CGFloat
    let xOffset: CGFloat
    let yOffset: CGFloat
    let duration: Double
    let delay: Double

    @State private var offset: CGSize = .zero

    var body: some View {
        Circle()
            .fill(Color(hex: "64B4FF")!.opacity(0.2))
            .frame(width: size, height: size)
            .offset(offset)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    offset = CGSize(width: xOffset, height: yOffset)
                }
            }
    }
}

// MARK: - BP Logo with Wave Circle
struct LoginBPLogo: View {
    @State private var outerRotation: Double = 0
    @State private var innerRotation: Double = 0

    var body: some View {
        ZStack {
            // Outer dotted ring
            Circle()
                .stroke(
                    Color(hex: "64B4FF")!.opacity(0.4),
                    style: StrokeStyle(lineWidth: 1, dash: [2, 5])
                )
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(outerRotation))

            // Inner dotted ring
            Circle()
                .stroke(
                    Color(hex: "64B4FF")!.opacity(0.2),
                    style: StrokeStyle(lineWidth: 0.5, dash: [1, 4])
                )
                .frame(width: 85, height: 85)
                .rotationEffect(.degrees(innerRotation))

            // BP Text
            HStack(spacing: -2) {
                Text("B")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text("P")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(hex: "64B4FF")!)
            }
            .shadow(color: Color(hex: "64B4FF")!.opacity(0.5), radius: 20, x: 0, y: 0)
        }
        .frame(width: 100, height: 100)
        .onAppear {
            withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
                outerRotation = 360
            }
            withAnimation(.linear(duration: 18).repeatForever(autoreverses: false)) {
                innerRotation = -360
            }
        }
    }
}

// MARK: - Custom Text Field
struct CustomTextField: View {
    let icon: String
    let placeholder: String
    let isSecure: Bool
    @Binding var text: String
    @FocusState var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(placeholder)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1)
                .textCase(.uppercase)
                .padding(.leading, 4)

            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "64B4FF")!.opacity(0.5))
                    .frame(width: 20)

                if isSecure {
                    SecureField("", text: $text)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .focused($isFocused)
                } else {
                    TextField("", text: $text)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .focused($isFocused)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                }

                if isSecure {
                    Image(systemName: "eye")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "64B4FF")!.opacity(0.4))
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isFocused ? Color.white.opacity(0.08) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "64B4FF")!.opacity(isFocused ? 0.5 : 0.15), lineWidth: 1)
                    )
                    .shadow(color: isFocused ? Color(hex: "64B4FF")!.opacity(0.1) : .clear, radius: 20, x: 0, y: 0)
            )
        }
    }
}

// MARK: - Social Login Button
struct SocialButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(label)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(.white.opacity(0.7))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(hex: "64B4FF")!.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Security Badge
struct SecurityBadge: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "64B4FF")!.opacity(0.5))

            Text("End-to-End Encrypted")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color(hex: "64B4FF")!.opacity(0.4))
                .tracking(1)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.03))
                .overlay(
                    Capsule()
                        .stroke(Color(hex: "64B4FF")!.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Main Login View
struct LoginView: View {
    var onLoginSuccess: (() -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @StateObject private var dataService = DataService.shared
    @State private var authService = AuthService.shared

    @State private var showSignUp: Bool = false
    @State private var showForgotPassword: Bool = false
    @State private var rememberMe: Bool = true
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false

    private func authenticateWithBiometrics() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Secure access to your account"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                DispatchQueue.main.async {
                    if success {
                        print("Biometric auth successful")
                        onLoginSuccess?()
                    }
                }
            }
        }
    }

    private func validateAndLogin() {
        guard !email.isEmpty else {
            showErrorToast(message: "Email tidak boleh kosong")
            return
        }
        guard !password.isEmpty else {
            showErrorToast(message: "Password tidak boleh kosong")
            return
        }

        isLoading = true

        Task {
            await authService.signIn(email: email, password: password, modelContext: modelContext)

            await MainActor.run {
                isLoading = false
                if authService.isAuthenticated {
                    UserDefaults.standard.set(true, forKey: "isUserLoggedIn")
                    UserDefaults.standard.set(rememberMe, forKey: "rememberMe")
                    UserDefaults.standard.synchronize()
                    onLoginSuccess?()
                } else if let error = authService.errorMessage {
                    showErrorToast(message: error)
                }
            }
        }
    }

    private func signInWithGoogle() {
        isLoading = true
        Task {
            await authService.signInWithGoogle(modelContext: modelContext)

            await MainActor.run {
                isLoading = false
                if authService.isAuthenticated {
                    UserDefaults.standard.set(true, forKey: "isUserLoggedIn")
                    UserDefaults.standard.set(rememberMe, forKey: "rememberMe")
                    UserDefaults.standard.synchronize()
                    onLoginSuccess?()
                } else if let error = authService.errorMessage {
                    showErrorToast(message: error)
                }
            }
        }
    }

    private func showErrorToast(message: String) {
        errorMessage = message
        showError = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showError = false
        }
    }

    var body: some View {
        ZStack {
            // Error Toast
            VStack {
                if showError {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)

                        Text(errorMessage)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "DC2626")!.opacity(0.9))
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 60)
                }

                Spacer()
            }
            .zIndex(100)
            .animation(.easeInOut(duration: 0.3), value: showError)

            // Background Gradient
            LinearGradient(
                colors: [
                    Color(hex: "2C5282")!,
                    Color(hex: "0B1220")!
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Floating Particles
            LoginParticle(size: 3, xOffset: 5, yOffset: -10, duration: 6, delay: 0)
                .position(x: 60, y: 80)

            LoginParticle(size: 2, xOffset: -6, yOffset: 8, duration: 7, delay: 1)
                .position(x: 320, y: 200)

            LoginParticle(size: 2.5, xOffset: -4, yOffset: -6, duration: 5, delay: 0.5)
                .position(x: 40, y: 450)

            LoginParticle(size: 2, xOffset: 4, yOffset: 5, duration: 8, delay: 2)
                .position(x: 340, y: 550)

            LoginParticle(size: 1.5, xOffset: -5, yOffset: 3, duration: 6, delay: 1.5)
                .position(x: 300, y: 320)

            // Content
            VStack(spacing: 0) {
                Spacer().frame(height: 100)

                // Logo
                LoginBPLogo()
                    .padding(.bottom, 12)

                // Tagline
                Text("Secure Your Future")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: "64B4FF")!.opacity(0.5))
                    .tracking(4)
                    .textCase(.uppercase)
                    .padding(.bottom, 56)

                // Form
                VStack(spacing: 16) {
                    CustomTextField(
                        icon: "envelope",
                        placeholder: "Email",
                        isSecure: false,
                        text: $email
                    )

                    CustomTextField(
                        icon: "lock",
                        placeholder: "Password",
                        isSecure: true,
                        text: $password
                    )
                }
                .padding(.horizontal, 32)

                // Remember Me & Forgot Password
                HStack(spacing: 0) {
                    // Remember Me
                    Button(action: {
                        rememberMe.toggle()
                    }) {
                        HStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color(hex: "64B4FF")!.opacity(rememberMe ? 0.8 : 0.3), lineWidth: 1.5)
                                    .frame(width: 18, height: 18)

                                if rememberMe {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Color(hex: "64B4FF")!)
                                }
                            }

                            Text("Remember Me")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: "8B9BB4")!)
                        }
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Forgot Password
                    Button(action: {
                        showForgotPassword = true
                    }) {
                        Text("Forgot Password?")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "64B4FF")!.opacity(0.6))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 16)
                .padding(.bottom, 32)
                .sheet(isPresented: $showForgotPassword) {
                    ForgotPasswordView()
                }

                // Sign In Button
                Button(action: {
                    validateAndLogin()
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "64B4FF")!, Color(hex: "3C8CDC")!],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 56)
                            .shadow(color: Color(hex: "64B4FF")!.opacity(0.3), radius: 20, x: 0, y: 10)

                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Sign In")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .tracking(1)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .disabled(isLoading)

                // Divider
                HStack(spacing: 16) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, Color(hex: "64B4FF")!.opacity(0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)

                    Text("or")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                        .tracking(2)
                        .textCase(.uppercase)

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "64B4FF")!.opacity(0.2), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 32)

                // Social Login
                HStack(spacing: 12) {
                    SocialButton(icon: "globe", label: "Google") {
                        signInWithGoogle()
                    }
                    SocialButton(icon: "apple.logo", label: "Apple") {
                        // Apple Sign In - belum diimplementasikan
                    }
                }
                .padding(.horizontal, 32)

                Spacer()

                // Sign Up
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.4))

                    Button(action: {
                        showSignUp = true
                    }) {
                        Text("Sign Up")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "64B4FF")!)
                    }
                }
                .padding(.bottom, 16)
                .sheet(isPresented: $showSignUp) {
                    SignUpView(onSignUpSuccess: {
                        showSignUp = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            onLoginSuccess?()
                        }
                    })
                }

                // Security Badge
                SecurityBadge()
                    .padding(.bottom, 24)
            }
        }
    }
}

// MARK: - Sign Up View
struct SignUpView: View {
    var onSignUpSuccess: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var dataService = DataService.shared
    @State private var authService = AuthService.shared

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var selectedRole: UserRole = .husband
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false

    private func showErrorToast(message: String) {
        errorMessage = message
        showError = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showError = false
        }
    }

    private func validateAndSignUp() {
        guard !name.isEmpty else {
            showErrorToast(message: "Nama tidak boleh kosong")
            return
        }
        guard !email.isEmpty else {
            showErrorToast(message: "Email tidak boleh kosong")
            return
        }
        guard email.contains("@") else {
            showErrorToast(message: "Format email tidak valid")
            return
        }
        guard !password.isEmpty else {
            showErrorToast(message: "Password tidak boleh kosong")
            return
        }
        guard password.count >= 6 else {
            showErrorToast(message: "Password minimal 6 karakter")
            return
        }
        guard password == confirmPassword else {
            showErrorToast(message: "Password tidak cocok")
            return
        }

        isLoading = true

        Task {
            await authService.signUp(
                email: email,
                password: password,
                displayName: name,
                role: selectedRole,
                modelContext: modelContext
            )

            await MainActor.run {
                isLoading = false
                if authService.isAuthenticated {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onSignUpSuccess?()
                    }
                } else if let error = authService.errorMessage {
                    showErrorToast(message: error)
                }
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(hex: "0B1220")!
                    .ignoresSafeArea()

                // Error Toast
                VStack {
                    if showError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)

                            Text(errorMessage)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "DC2626")!.opacity(0.9))
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 60)
                    }

                    Spacer()
                }
                .zIndex(100)
                .animation(.easeInOut(duration: 0.3), value: showError)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 40)

                        // Title
                        Text("Buat Akun")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.bottom, 8)

                        Text("Daftar untuk mulai mengatur keuangan")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.bottom, 40)

                        // Form
                        VStack(spacing: 20) {
                            // Name
                            CustomTextField(
                                icon: "person",
                                placeholder: "Nama Lengkap",
                                isSecure: false,
                                text: $name
                            )

                            // Email
                            CustomTextField(
                                icon: "envelope",
                                placeholder: "Email",
                                isSecure: false,
                                text: $email
                            )

                            // Password
                            CustomTextField(
                                icon: "lock",
                                placeholder: "Password",
                                isSecure: true,
                                text: $password
                            )

                            // Confirm Password
                            CustomTextField(
                                icon: "lock.shield",
                                placeholder: "Konfirmasi Password",
                                isSecure: true,
                                text: $confirmPassword
                            )

                            // Role Selection
                            VStack(alignment: .leading, spacing: 8) {
                                Text("PERAN")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.4))
                                    .tracking(1)
                                    .padding(.leading, 4)

                                HStack(spacing: 12) {
                                    ForEach(UserRole.allCases, id: \.self) { role in
                                        Button(action: {
                                            selectedRole = role
                                        }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: role == .husband ? "person.fill" : "person.fill")
                                                    .font(.system(size: 16))
                                                Text(role.rawValue)
                                                    .font(.system(size: 14, weight: .medium))
                                            }
                                            .foregroundColor(selectedRole == role ? .white : .white.opacity(0.5))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 48)
                                            .background(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .fill(selectedRole == role ? Color(hex: "64B4FF")!.opacity(0.25) : Color.white.opacity(0.05))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 14)
                                                            .stroke(selectedRole == role ? Color(hex: "64B4FF")!.opacity(0.5) : Color(hex: "64B4FF")!.opacity(0.1), lineWidth: 1)
                                                    )
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 32)

                        // Sign Up Button
                        Button(action: {
                            validateAndSignUp()
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "64B4FF")!, Color(hex: "3C8CDC")!],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(height: 56)
                                    .shadow(color: Color(hex: "64B4FF")!.opacity(0.3), radius: 20, x: 0, y: 10)

                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Daftar")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .tracking(1)
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 32)
                        .disabled(isLoading)

                        Spacer().frame(height: 40)
                    }
                }
            }
            .navigationTitle("Daftar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "0B1220")!, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .tint(.white)
        }
    }
}

// MARK: - Preview
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
