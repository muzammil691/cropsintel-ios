import SwiftUI
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var email = ""
    @Published var password = ""
    @Published var showBiometricOption = false

    private let supabase = SupabaseService.shared
    private let keychain = KeychainService.shared
    private let biometric = BiometricService.shared

    init() {
        checkExistingSession()
    }

    private func checkExistingSession() {
        if let _ = keychain.getAccessToken() {
            isAuthenticated = true
            showBiometricOption = biometric.isBiometricAvailable
        }
    }

    func login() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password"
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let response = try await supabase.signIn(email: email, password: password)
                keychain.saveAccessToken(response.accessToken)
                keychain.saveRefreshToken(response.refreshToken)
                keychain.saveUserEmail(response.user.email ?? email)
                keychain.saveUserId(response.user.id)

                isAuthenticated = true
                password = ""
                showBiometricOption = biometric.isBiometricAvailable
            } catch let error as APIError {
                errorMessage = error.localizedDescription
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func loginWithBiometric() {
        Task {
            let success = await biometric.authenticate()
            if success {
                if let _ = keychain.getAccessToken() {
                    isAuthenticated = true
                }
            } else {
                errorMessage = "Biometric authentication failed"
            }
        }
    }

    func logout() {
        Task {
            try? await supabase.signOut()
            keychain.clearAll()
            isAuthenticated = false
            email = ""
            password = ""
        }
    }

    func refreshTokenIfNeeded() {
        guard let refreshToken = keychain.getRefreshToken() else { return }

        Task {
            do {
                let response = try await supabase.refreshSession(refreshToken: refreshToken)
                keychain.saveAccessToken(response.accessToken)
                keychain.saveRefreshToken(response.refreshToken)
            } catch {
                logout()
            }
        }
    }
}
