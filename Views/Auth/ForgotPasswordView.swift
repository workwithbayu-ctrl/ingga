import SwiftUI
import SwiftData

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataService = DataService.shared

    @State private var email: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var verificationCode: String = ""
    @State private var showCodeField: Bool = false
    @State private var showResetFields: Bool = false
    @State private var isLoading: Bool = false
    @State private var showSuccess: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @State private var generatedCode: String = ""
    @State private var shakeEmail: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(hex: "0B1220")!
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "64B4FF")!.opacity(0.1))
                                .frame(width: 80, height: 80)

                            Image(systemName: "lock.shield")
                                .font(.system(size: 32))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(hex: "64B4FF")!, Color(hex: "8B5CF6")!],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }

                        Text("Reset Password")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text(showResetFields 
                             ? "Create your new password" 
                             : (showCodeField 
                                ? "Enter the verification code sent to your email" 
                                : "Enter your email to receive a reset code"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "8B9BB4")!)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 40)

                    // Form
                    VStack(spacing: 20) {
                        // Email Field (always visible until reset)
                        if !showResetFields {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email Address")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(hex: "8B9BB4")!)

                                HStack(spacing: 12) {
                                    Image(systemName: "envelope")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color(hex: "64B4FF")!)

                                    TextField("Enter your email", text: $email)
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .keyboardType(.emailAddress)
                                        .textContentType(.emailAddress)
                                        .autocapitalization(.none)
                                        .disabled(showCodeField)
                                }
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
                                .offset(x: shakeEmail ? -10 : 0)
                                .animation(.default, value: shakeEmail)
                            }
                        }

                        // Verification Code Field
                        if showCodeField && !showResetFields {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Verification Code")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(hex: "8B9BB4")!)

                                HStack(spacing: 12) {
                                    Image(systemName: "number")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color(hex: "64B4FF")!)

                                    TextField("Enter 6-digit code", text: $verificationCode)
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .keyboardType(.numberPad)
                                }
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
                            }
                        }

                        // New Password Fields
                        if showResetFields {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("New Password")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(hex: "8B9BB4")!)

                                HStack(spacing: 12) {
                                    Image(systemName: "lock")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color(hex: "64B4FF")!)

                                    SecureField("Enter new password", text: $newPassword)
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .textContentType(.newPassword)
                                }
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
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(hex: "8B9BB4")!)

                                HStack(spacing: 12) {
                                    Image(systemName: "lock.rotation")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color(hex: "64B4FF")!)

                                    SecureField("Confirm new password", text: $confirmPassword)
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .textContentType(.newPassword)
                                }
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
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()

                    // Action Button
                    VStack(spacing: 16) {
                        Button(action: handleAction) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "64B4FF")!, Color(hex: "8B5CF6")!],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(height: 54)

                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(buttonTitle)
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .disabled(isLoading)
                        .padding(.horizontal, 24)

                        // Back to login
                        Button(action: { dismiss() }) {
                            Text("Back to Login")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color(hex: "64B4FF")!)
                        }
                    }
                    .padding(.bottom, 40)
                }

                // Error Toast
                if showError {
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
                        .padding(.top, 16)
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation { showError = false }
                        }
                    }
                }

                // Success Overlay
                if showSuccess {
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()

                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.2))
                                .frame(width: 80, height: 80)

                            Image(systemName: "checkmark")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.green)
                        }

                        Text("Password Reset Successful!")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)

                        Text("Your password has been updated.\nPlease login with your new password.")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "8B9BB4")!)
                            .multilineTextAlignment(.center)

                        Button(action: { dismiss() }) {
                            Text("Back to Login")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.green.opacity(0.8))
                                )
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 10)
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(hex: "1A1F3A")!)
                    )
                    .padding(.horizontal, 40)
                }
            }
            .navigationTitle("")
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
        }
    }

    private var buttonTitle: String {
        if showResetFields {
            return "Update Password"
        } else if showCodeField {
            return "Verify Code"
        } else {
            return "Send Reset Code"
        }
    }

    private func handleAction() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        if showResetFields {
            handleResetPassword()
        } else if showCodeField {
            handleVerifyCode()
        } else {
            handleSendCode()
        }
    }

    private func handleSendCode() {
        guard !email.isEmpty else {
            showErrorToast("Please enter your email address")
            shakeEmailField()
            return
        }

        guard email.contains("@") else {
            showErrorToast("Please enter a valid email address")
            shakeEmailField()
            return
        }

        // Check if user exists in database
        let users = dataService.fetchUsers()
        let userExists = users.contains { $0.email.lowercased() == email.lowercased() }

        guard userExists else {
            showErrorToast("No account found with this email")
            shakeEmailField()
            return
        }

        isLoading = true

        // Generate random 6-digit code
        generatedCode = String(format: "%06d", Int.random(in: 100000...999999))
        print("📧 Reset code for \(email): \(generatedCode)")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            withAnimation(.easeInOut(duration: 0.3)) {
                showCodeField = true
            }
            showErrorToast("Code sent! Check console for: \(generatedCode)")
        }
    }

    private func handleVerifyCode() {
        guard verificationCode.count == 6 else {
            showErrorToast("Please enter the 6-digit code")
            return
        }

        guard verificationCode == generatedCode else {
            showErrorToast("Invalid verification code")
            return
        }

        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isLoading = false
            withAnimation(.easeInOut(duration: 0.3)) {
                showResetFields = true
            }
        }
    }

    private func handleResetPassword() {
        guard newPassword.count >= 6 else {
            showErrorToast("Password must be at least 6 characters")
            return
        }

        guard newPassword == confirmPassword else {
            showErrorToast("Passwords do not match")
            return
        }

        isLoading = true

        // Update password in database
        let users = dataService.fetchUsers()
        if let user = users.first(where: { $0.email.lowercased() == email.lowercased() }) {
            user.password = newPassword
            dataService.save()
            print("🔐 Password updated for \(email)")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            withAnimation(.easeInOut(duration: 0.4)) {
                showSuccess = true
            }
        }
    }

    private func showErrorToast(_ message: String) {
        errorMessage = message
        withAnimation(.easeInOut(duration: 0.3)) {
            showError = true
        }
    }

    private func shakeEmailField() {
        withAnimation(.default) {
            shakeEmail = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            shakeEmail = false
        }
    }
}

#Preview {
    ForgotPasswordView()
}
