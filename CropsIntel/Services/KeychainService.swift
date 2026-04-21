import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()
    private let service = "com.cropsintel.app"

    private enum Keys {
        static let accessToken = "access_token"
        static let refreshToken = "refresh_token"
        static let userEmail = "user_email"
        static let userId = "user_id"
    }

    private init() {}

    // MARK: - Access Token
    func saveAccessToken(_ token: String) {
        save(key: Keys.accessToken, value: token)
    }

    func getAccessToken() -> String? {
        return load(key: Keys.accessToken)
    }

    // MARK: - Refresh Token
    func saveRefreshToken(_ token: String) {
        save(key: Keys.refreshToken, value: token)
    }

    func getRefreshToken() -> String? {
        return load(key: Keys.refreshToken)
    }

    // MARK: - User Info
    func saveUserEmail(_ email: String) {
        save(key: Keys.userEmail, value: email)
    }

    func getUserEmail() -> String? {
        return load(key: Keys.userEmail)
    }

    func saveUserId(_ id: String) {
        save(key: Keys.userId, value: id)
    }

    func getUserId() -> String? {
        return load(key: Keys.userId)
    }

    // MARK: - Clear All
    func clearAll() {
        delete(key: Keys.accessToken)
        delete(key: Keys.refreshToken)
        delete(key: Keys.userEmail)
        delete(key: Keys.userId)
    }

    // MARK: - Private Helpers
    private func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]

        SecItemDelete(query as CFDictionary)

        var newQuery = query
        newQuery[kSecValueData as String] = data
        newQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        SecItemAdd(newQuery as CFDictionary, nil)
    }

    private func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
