import SwiftUI

struct CreateFamilyView: View {
    @StateObject private var dataService = DataService.shared
    
    @State private var husbandName: String = ""
    @State private var wifeName: String = ""
    @State private var isSetup = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.primaryBlue)

                    Text("Family Budget Pro")
                        .font(.largeTitle.bold())

                    Text("Kelola keuangan keluarga bersama pasangan")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nama Suami")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        TextField("Masukkan nama suami", text: $husbandName)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nama Istri")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        TextField("Masukkan nama istri", text: $wifeName)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
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
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.primaryBlue)
                    )
                }
                .disabled(husbandName.isEmpty || wifeName.isEmpty)
                .padding(.horizontal)
                .padding(.bottom, 30)
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
