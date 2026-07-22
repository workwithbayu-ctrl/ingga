import SwiftUI

struct FamilySetupView: View {
    @State private var familyCode = ""
    @State private var isCreatingFamily = true
    @State private var isLoading = false
    @ObservedObject var authService = FirebaseAuthService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                // Dark background
                Color(hex: "0B1220")?.ignoresSafeArea() ?? Color.black.ignoresSafeArea()

                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "64B4FF")?.opacity(0.15) ?? Color.blue.opacity(0.15))
                            .frame(width: 80, height: 80)

                        Image(systemName: "person.2.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "64B4FF") ?? .blue, Color(hex: "8B5CF6") ?? .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .padding(.top, 20)

                    Text("Setup Keluarga")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Hubungkan akun dengan pasangan untuk memantau keuangan bersama")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal)

                    // Tab selector
                    HStack(spacing: 4) {
                        ForEach([true, false], id: \.self) { isCreate in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isCreatingFamily = isCreate
                                }
                            }) {
                                Text(isCreate ? "Buat Keluarga" : "Gabung Keluarga")
                                    .font(.system(size: 14, weight: isCreatingFamily == isCreate ? .semibold : .medium))
                                    .foregroundColor(isCreatingFamily == isCreate ? .white : .white.opacity(0.6))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        isCreatingFamily == isCreate ?
                                        Color(hex: "64B4FF")?.opacity(0.3) ?? Color.blue.opacity(0.3) :
                                        Color.clear
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(4)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    if isCreatingFamily {
                        VStack(spacing: 16) {
                            Text("Buat keluarga baru dan bagikan kode dengan istri/suami")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white.opacity(0.6))

                            Button {
                                isLoading = true
                                Task {
                                    if let familyID = await authService.createFamily() {
                                        print("Family ID: \(familyID)")
                                    }
                                    isLoading = false
                                }
                            } label: {
                                HStack {
                                    Spacer()
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Label("Buat Keluarga", systemImage: "plus.circle.fill")
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "64B4FF") ?? .blue, Color(hex: "3C8CDC") ?? .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(20)
                                .shadow(color: Color(hex: "64B4FF")?.opacity(0.3) ?? Color.blue.opacity(0.3), radius: 15, x: 0, y: 8)
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        VStack(spacing: 16) {
                            Text("Masukkan kode keluarga dari suami/istri")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white.opacity(0.6))

                            HStack(spacing: 12) {
                                Image(systemName: "number")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(hex: "64B4FF") ?? .blue)
                                    .frame(width: 20)

                                TextField("Kode Keluarga", text: $familyCode)
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)
                                    .autocapitalization(.none)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color(hex: "64B4FF")?.opacity(0.2) ?? Color.blue.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal)

                            Button {
                                isLoading = true
                                Task {
                                    await authService.joinFamily(familyID: familyCode)
                                    isLoading = false
                                }
                            } label: {
                                HStack {
                                    Spacer()
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Label("Gabung", systemImage: "person.badge.plus")
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "64B4FF") ?? .blue, Color(hex: "3C8CDC") ?? .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(20)
                                .shadow(color: Color(hex: "64B4FF")?.opacity(0.3) ?? Color.blue.opacity(0.3), radius: 15, x: 0, y: 8)
                            }
                            .padding(.horizontal)
                            .disabled(familyCode.isEmpty)
                            .opacity(familyCode.isEmpty ? 0.5 : 1)
                        }
                    }

                    Spacer()
                }
            }
            .navigationTitle("Keluarga")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Tutup") {
                        // dismiss action
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}
