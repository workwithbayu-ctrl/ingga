import SwiftUI

struct CreateFamilyView: View {
    @StateObject private var dataService = DataService.shared

    @State private var husbandName: String = ""
    @State private var wifeName: String = ""
    @State private var isSetup = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Dark background
                Color(hex: "0B1220")?.ignoresSafeArea() ?? Color.black.ignoresSafeArea()

                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "64B4FF")?.opacity(0.15) ?? Color.blue.opacity(0.15))
                                .frame(width: 80, height: 80)

                            Image(systemName: "house.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(hex: "64B4FF") ?? .blue, Color(hex: "8B5CF6") ?? .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }

                        Text("Family Budget Pro")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("Kelola keuangan keluarga bersama pasangan")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)

                    VStack(spacing: 20) {
                        // Husband Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nama Suami")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(1)
                                .textCase(.uppercase)
                                .padding(.leading, 4)

                            HStack(spacing: 12) {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(hex: "64B4FF") ?? .blue)
                                    .frame(width: 20)

                                TextField("Masukkan nama suami", text: $husbandName)
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)
                                    .autocorrectionDisabled()
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
                        }

                        // Wife Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nama Istri")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(1)
                                .textCase(.uppercase)
                                .padding(.leading, 4)

                            HStack(spacing: 12) {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(hex: "FF2D92") ?? .pink)
                                    .frame(width: 20)

                                TextField("Masukkan nama istri", text: $wifeName)
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)
                                    .autocorrectionDisabled()
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
                        }
                    }
                    .padding(.horizontal)

                    Spacer()

                    Button {
                        setupFamily()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Mulai")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
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
                    .disabled(husbandName.isEmpty || wifeName.isEmpty)
                    .opacity(husbandName.isEmpty || wifeName.isEmpty ? 0.5 : 1)
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
        }
        .fullScreenCover(isPresented: $isSetup) {
            DashboardView()
        }
    }

    private func setupFamily() {
        let users = dataService.fetchUsers()
        if let husband = users.first(where: { $0.role == .husband }) {
            husband.name = husbandName
        }
        if let wife = users.first(where: { $0.role == .wife }) {
            wife.name = wifeName
        }
        dataService.save()
        dataService.setupDefaultData()
        isSetup = true
    }
}
