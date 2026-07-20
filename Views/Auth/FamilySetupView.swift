import SwiftUI

struct FamilySetupView: View {
    @State private var familyCode = ""
    @State private var isCreatingFamily = true
    @State private var isLoading = false
    @ObservedObject var authService = FirebaseAuthService.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "person.2.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.primaryBlue)
                
                Text("Setup Keluarga")
                    .font(.largeTitle.bold())
                
                Text("Hubungkan akun dengan pasangan untuk memantau keuangan bersama")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                
                Picker("", selection: $isCreatingFamily) {
                    Text("Buat Keluarga Baru").tag(true)
                    Text("Gabung Keluarga").tag(false)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                if isCreatingFamily {
                    VStack(spacing: 16) {
                        Text("Buat keluarga baru dan bagikan kode dengan istri/suami")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        
                        Button {
                            isLoading = true
                            Task {
                                if let familyID = await authService.createFamily() {
                                    // Show family code
                                    print("Family ID: \(familyID)")
                                }
                                isLoading = false
                            }
                        } label: {
                            HStack {
                                Spacer()
                                if isLoading {
                                    ProgressView()
                                } else {
                                    Label("Buat Keluarga", systemImage: "plus.circle.fill")
                                        .fontWeight(.semibold)
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.primaryBlue)
                        .padding(.horizontal)
                    }
                } else {
                    VStack(spacing: 16) {
                        Text("Masukkan kode keluarga dari suami/istri")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        
                        TextField("Kode Keluarga", text: $familyCode)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
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
                                } else {
                                    Label("Gabung", systemImage: "person.badge.plus")
                                        .fontWeight(.semibold)
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.primaryBlue)
                        .padding(.horizontal)
                        .disabled(familyCode.isEmpty)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Keluarga")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
