// ProfileView.swift
// Views/Settings/ProfileView.swift

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = "Suami"
    @State private var email = "suami@family.com"
    @State private var phone = "+62 812-3456-7890"
    @State private var showImagePicker = false
    @State private var avatarImage: Image? = nil

    var body: some View {
        ZStack {
            Color(hex: "0B1220")!
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Avatar Section
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "2C5282")!, Color(hex: "1A365D")!],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 3)
                                )

                            if let avatar = avatarImage {
                                avatar
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                Text("S")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            // Edit badge
                            Circle()
                                .fill(Color(hex: "64B4FF")!)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                )
                                .offset(x: 35, y: 35)
                        }
                        .onTapGesture {
                            showImagePicker = true
                        }

                        Text(name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)

                        Text("Anggota Keluarga")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 20)

                    // Form Fields
                    VStack(spacing: 16) {
                        ProfileTextField(title: "Nama Lengkap", text: $name, icon: "person.fill")
                        ProfileTextField(title: "Email", text: $email, icon: "envelope.fill", keyboard: .emailAddress)
                        ProfileTextField(title: "Nomor Telepon", text: $phone, icon: "phone.fill", keyboard: .phonePad)
                    }
                    .padding(.horizontal, 20)

                    // Family Members Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Anggota Keluarga")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)

                        VStack(spacing: 8) {
                            FamilyMemberRow(name: "Suami", role: "Admin", color: "2C5282", isActive: true)
                            FamilyMemberRow(name: "Istri", role: "Anggota", color: "805AD5", isActive: false)
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 40)

                    // Save Button
                    Button {
                        // Save profile changes
                    } label: {
                        Text("Simpan Perubahan")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "2C5282")!, Color(hex: "1A365D")!],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationTitle("Profil")
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
        .sheet(isPresented: $showImagePicker) {
            // Image picker placeholder
            Text("Pilih Foto")
        }
    }
}

// MARK: - Profile Text Field
struct ProfileTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.7))

            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "64B4FF")!)
                    .frame(width: 24)

                TextField("", text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .keyboardType(keyboard)
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

// MARK: - Family Member Row
struct FamilyMemberRow: View {
    let name: String
    let role: String
    let color: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: color)!)
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(name.prefix(1)))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(role)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            if isActive {
                Text("Aktif")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(8)
            }
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
