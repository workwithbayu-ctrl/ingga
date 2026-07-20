import SwiftUI

struct RegisterView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var selectedRole: UserRole = .husband
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss
    @StateObject var authService = FirebaseAuthService.shared
    
    var isValid: Bool {
        !name.isEmpty && !email.isEmpty && password.count >= 6 && password == confirmPassword
    }
    
    var body: some View {
        Form {
            Section("Profil") {
                TextField("Nama", text: $name)
                
                Picker("Peran", selection: $selectedRole) {
                    Text("Suami").tag(UserRole.husband)
                    Text("Istri").tag(UserRole.wife)
                }
                .pickerStyle(.segmented)
            }
            
            Section("Akun") {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                
                SecureField("Password (min 6 karakter)", text: $password)
                
                SecureField("Konfirmasi Password", text: $confirmPassword)
            }
            
            if password != confirmPassword && !confirmPassword.isEmpty {
                Section {
                    Text("Password tidak cocok")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
            
            // FIX: Tampilkan error detail
            if let error = authService.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
            
            Section {
                Button {
                    isLoading = true
                    authService.errorMessage = nil // Clear previous error
                    Task {
                        await authService.signUp(email: email, password: password, name: name, role: selectedRole)
                        isLoading = false
                    }
                } label: {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Daftar")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(!isValid || isLoading)
            }
        }
        .navigationTitle("Daftar Akun")
        .navigationBarTitleDisplayMode(.inline)
    }
}
