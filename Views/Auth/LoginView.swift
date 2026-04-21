import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer().frame(height: 60)

                    // Logo
                    VStack(spacing: 12) {
                        // CI Text Logo
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.darkBackground)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.amberAccent, lineWidth: 2)
                                )

                            Text("CI")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.amberAccent)
                        }

                        Text("CropsIntel")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)

                        Text("Almond Market Intelligence by MAXONS")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }

                    // Login Form
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.caption)
                                .foregroundColor(.textSecondary)

                            TextField("", text: $authViewModel.email)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color.darkSurface)
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.amberAccent.opacity(0.3), lineWidth: 1)
                                )
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.caption)
                                .foregroundColor(.textSecondary)

                            SecureField("", text: $authViewModel.password)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color.darkSurface)
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .textContentType(.password)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.amberAccent.opacity(0.3), lineWidth: 1)
                                )
                        }

                        if let error = authViewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }

                        Button(action: authViewModel.login) {
                            HStack {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .tint(.darkBackground)
                                } else {
                                    Text("Sign In")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.amberAccent)
                            .foregroundColor(.darkBackground)
                            .cornerRadius(12)
                        }
                        .disabled(authViewModel.isLoading)

                        if authViewModel.showBiometricOption {
                            Button(action: authViewModel.loginWithBiometric) {
                                HStack(spacing: 8) {
                                    Image(systemName: BiometricService.shared.biometricType == .faceID
                                        ? "faceid" : "touchid")
                                    Text("Sign in with \(BiometricService.shared.biometricType == .faceID ? "Face ID" : "Touch ID")")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.darkSurface)
                                .foregroundColor(.amberAccent)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.amberAccent, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 32)

                    Spacer()

                    Text("Powered by MAXONS Group")
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                        .padding(.bottom, 20)
                }
            }
        }
    }
}
