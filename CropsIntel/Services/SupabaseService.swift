import Foundation
import Combine

// MARK: - Supabase Configuration
enum SupabaseConfig {
    static let projectURL = "https://knicjcmgizovpsnmbwex.supabase.co"
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtuaWNqY21naXpvdnBzbm1id2V4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAwMDYxMzksImV4cCI6MjA3NTU4MjEzOX0.wP20A4Odg9-4Mp8ZITTqUrmw33qsYMc-F4vlU-S4vbU"
    static let restURL = "\(projectURL)/rest/v1"
    static let authURL = "\(projectURL)/auth/v1"
}

// MARK: - Supabase Auth Response
struct SupabaseAuthResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let expiresAt: Int?
    let refreshToken: String
    let user: SupabaseUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case expiresAt = "expires_at"
        case refreshToken = "refresh_token"
        case user
    }
}

struct SupabaseUser: Codable {
    let id: String
    let email: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, email
        case createdAt = "created_at"
    }
}

struct SupabaseAuthError: Codable {
    let error: String?
    let errorDescription: String?
    let msg: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
        case msg, message
    }

    var displayMessage: String {
        errorDescription ?? message ?? msg ?? error ?? "Authentication failed"
    }
}

// MARK: - Supabase Service
final class SupabaseService {
    static let shared = SupabaseService()

    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
        decoder = JSONDecoder()
    }

    // MARK: - Auth: Sign In with email/password
    func signIn(email: String, password: String) async throws -> SupabaseAuthResponse {
        let url = URL(string: "\(SupabaseConfig.authURL)/token?grant_type=password")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")

        let body = ["email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(NSError(domain: "", code: -1))
        }

        if httpResponse.statusCode == 200 {
            return try decoder.decode(SupabaseAuthResponse.self, from: data)
        } else {
            if let authError = try? decoder.decode(SupabaseAuthError.self, from: data) {
                throw APIError.serverError(authError.displayMessage)
            }
            throw APIError.serverError("Authentication failed (\(httpResponse.statusCode))")
        }
    }

    // MARK: - Auth: Refresh Token
    func refreshSession(refreshToken: String) async throws -> SupabaseAuthResponse {
        let url = URL(string: "\(SupabaseConfig.authURL)/token?grant_type=refresh_token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")

        let body = ["refresh_token": refreshToken]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(NSError(domain: "", code: -1))
        }

        if httpResponse.statusCode == 200 {
            return try decoder.decode(SupabaseAuthResponse.self, from: data)
        } else {
            throw APIError.unauthorized
        }
    }

    // MARK: - Auth: Sign Out
    func signOut() async throws {
        guard let token = KeychainService.shared.getAccessToken() else { return }
        let url = URL(string: "\(SupabaseConfig.authURL)/logout")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let _ = try? await session.data(for: request)
    }

    // MARK: - PostgREST: Generic table query
    func query<T: Codable>(
        table: String,
        select: String = "*",
        filters: [String: String] = [:],
        order: String? = nil,
        limit: Int? = nil,
        isSingle: Bool = false
    ) async throws -> T {
        var components = URLComponents(string: "\(SupabaseConfig.restURL)/\(table)")!
        var queryItems = [URLQueryItem(name: "select", value: select)]

        for (key, value) in filters {
            queryItems.append(URLQueryItem(name: key, value: value))
        }

        if let order = order {
            queryItems.append(URLQueryItem(name: "order", value: order))
        }

        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: "\(limit)"))
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")

        if let token = KeychainService.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if isSingle {
            request.setValue("application/vnd.pgrst.object+json", forHTTPHeaderField: "Accept")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(NSError(domain: "", code: -1))
        }

        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        case 401:
            throw APIError.unauthorized
        default:
            throw APIError.serverError("Query failed (\(httpResponse.statusCode))")
        }
    }

    // MARK: - RPC: Call a Supabase function
    func rpc<T: Codable>(
        functionName: String,
        params: [String: Any] = [:]
    ) async throws -> T {
        let url = URL(string: "\(SupabaseConfig.restURL)/rpc/\(functionName)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")

        if let token = KeychainService.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if !params.isEmpty {
            request.httpBody = try JSONSerialization.data(withJSONObject: params)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(NSError(domain: "", code: -1))
        }

        switch httpResponse.statusCode {
        case 200...299:
            return try decoder.decode(T.self, from: data)
        case 401:
            throw APIError.unauthorized
        default:
            throw APIError.serverError("RPC failed (\(httpResponse.statusCode))")
        }
    }
}
