import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState
    @AppStorage("notifications_enabled") private var notificationsEnabled = true
    @AppStorage("biometric_enabled") private var biometricEnabled = false
    @State private var showLogoutConfirmation = false

    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Profile Section
                    VStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.amberAccent)

                        Text(KeychainService.shared.getUserEmail() ?? "User")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text("CropsIntel by MAXONS")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.top, 20)

                    // Settings Groups
                    SettingsGroup(title: "Preferences") {
                        SettingsRow(icon: "calendar", title: "Default Crop Year", value: "CY \(appState.currentCropYear)")

                        SettingsToggle(icon: "bell.fill", title: "Push Notifications", isOn: $notificationsEnabled)

                        if BiometricService.shared.isBiometricAvailable {
                            SettingsToggle(
                                icon: BiometricService.shared.biometricType == .faceID ? "faceid" : "touchid",
                                title: "Biometric Login",
                                isOn: $biometricEnabled
                            )
                        }
                    }

                    SettingsGroup(title: "Data") {
                        SettingsRow(icon: "arrow.clockwise", title: "Refresh Interval", value: "15 min")
                        SettingsRow(icon: "internaldrive", title: "Cache Size", value: "12 MB")
                        Button(action: {}) {
                            SettingsRow(icon: "trash", title: "Clear Cache", value: "", showChevron: true)
                        }
                    }

                    SettingsGroup(title: "About") {
                        SettingsRow(icon: "info.circle", title: "Version", value: "1.0.0")
                        SettingsRow(icon: "doc.text", title: "Terms of Service", value: "", showChevron: true)
                        SettingsRow(icon: "lock.shield", title: "Privacy Policy", value: "", showChevron: true)
                        SettingsRow(icon: "questionmark.circle", title: "Support", value: "", showChevron: true)
                    }

                    // Logout Button
                    Button(action: { showLogoutConfirmation = true }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.15))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    Text("Powered by MAXONS Group")
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                        .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Sign Out", isPresented: $showLogoutConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                authViewModel.logout()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

// MARK: - Settings Components
struct SettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.textSecondary)
                .padding(.horizontal)
                .padding(.bottom, 8)

            VStack(spacing: 1) {
                content
            }
            .background(Color.darkSurface)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let value: String
    var showChevron: Bool = false

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.tealPrimary)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.white)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundColor(.textSecondary)

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding()
    }
}

struct SettingsToggle: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.tealPrimary)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.white)

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(.tealPrimary)
        }
        .padding()
    }
}
