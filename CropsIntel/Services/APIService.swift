import Foundation
import Combine

// MARK: - API Error Types
enum APIError: Error, LocalizedError {
    case invalidURL
    case unauthorized
    case rateLimited
    case serverError(String)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .unauthorized: return "Session expired. Please sign in again."
        case .rateLimited: return "Too many requests. Please wait."
        case .serverError(let msg): return msg
        case .decodingError(let err): return "Data error: \(err.localizedDescription)"
        case .networkError(let err): return err.localizedDescription
        }
    }
}

// MARK: - API Response Wrapper (kept for model compatibility)
struct ApiResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let error: ApiErrorBody?
}

struct ApiErrorBody: Codable {
    let code: String?
    let message: String
}

// MARK: - APIService (Supabase PostgREST-backed)
final class APIService {
    static let shared = APIService()

    private let supabase = SupabaseService.shared

    private init() {}

    // MARK: - Auth (delegates to SupabaseService)
    func login(email: String, password: String) async throws -> LoginResponse {
        let response = try await supabase.signIn(email: email, password: password)
        return LoginResponse(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresIn: response.expiresIn,
            tokenType: response.tokenType,
            user: AuthUser(
                id: response.user.id,
                email: response.user.email ?? email,
                createdAt: response.user.createdAt
            )
        )
    }

    func refreshToken(refreshToken: String) async throws -> AuthTokens {
        let response = try await supabase.refreshSession(refreshToken: refreshToken)
        return AuthTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresIn: response.expiresIn,
            tokenType: response.tokenType
        )
    }

    func logout() async throws {
        try await supabase.signOut()
    }

    // MARK: - Helpers
    private func fetchRows(cropYear: Int, select: String = "*") async throws -> [AlmondDataRow] {
        let startDate = "\(cropYear)-08-01T00:00:00+00:00"
        let endDate = "\(cropYear + 1)-08-01T00:00:00+00:00"
        return try await supabase.query(
            table: "almond_data_combined",
            select: select,
            filters: [
                "created_at": "gte.\(startDate)",
                "crop_year": "eq.\(cropYear)"
            ]
        )
    }

    private func parseDate(_ dateStr: String) -> Date? {
        let f1 = ISO8601DateFormatter()
        f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f1.date(from: dateStr) { return d }
        let f2 = ISO8601DateFormatter()
        f2.formatOptions = [.withInternetDateTime]
        return f2.date(from: dateStr)
    }

    // MARK: - Market Summary
    func getMarketSummary(cropYear: Int? = nil) async throws -> MarketSummary {
        let year = cropYear ?? currentCropYear()
        let rows = try await fetchRows(cropYear: year, select: "id,volume_lbs,price_per_lb,variety,destination_country,buyer_name,handler_name")

        let totalVolumeLbs = rows.compactMap { $0.volumeLbs }.reduce(0, +)
        let prices = rows.compactMap { $0.pricePerLb }
        let avgPrice = prices.isEmpty ? 0 : prices.reduce(0, +) / Double(prices.count)

        return MarketSummary(
            cropYear: year,
            totalVolumeMLbs: Double(totalVolumeLbs) / 1_000_000.0,
            avgPricePerLb: avgPrice,
            volumeChangePct: 0,
            priceChangePct: 0,
            uniqueVarieties: Set(rows.compactMap { $0.variety }).count,
            uniqueDestinations: Set(rows.compactMap { $0.destinationCountry }).count,
            uniqueBuyers: Set(rows.compactMap { $0.buyerName }).count,
            uniqueHandlers: Set(rows.compactMap { $0.handlerName }).count,
            totalTransactions: rows.count
        )
    }

    // MARK: - Volume
    func getVolumeData(cropYear: Int? = nil, period: String = "monthly", variety: String? = nil, handler: String? = nil) async throws -> [VolumeDataPoint] {
        let year = cropYear ?? currentCropYear()
        let rows = try await fetchRows(cropYear: year, select: "created_at,volume_lbs")

        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "yyyy-MM"

        var monthlyVolume: [String: Int64] = [:]
        for row in rows {
            guard let dateStr = row.createdAt, let date = parseDate(dateStr), let vol = row.volumeLbs else { continue }
            let key = monthFormatter.string(from: date)
            monthlyVolume[key, default: 0] += vol
        }

        return monthlyVolume.keys.sorted().map { month in
            VolumeDataPoint(
                period: month,
                volumeMLbs: Double(monthlyVolume[month] ?? 0) / 1_000_000.0,
                volumeLbs: monthlyVolume[month] ?? 0
            )
        }
    }

    // MARK: - Price
    func getPriceData(cropYear: Int? = nil, variety: String? = nil) async throws -> [PriceDataPoint] {
        let year = cropYear ?? currentCropYear()
        let rows = try await fetchRows(cropYear: year, select: "created_at,price_per_lb,volume_lbs")

        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "yyyy-MM"

        var monthlyPrices: [String: [Double]] = [:]
        var monthlyVolume: [String: Int64] = [:]
        for row in rows {
            guard let dateStr = row.createdAt, let date = parseDate(dateStr) else { continue }
            let key = monthFormatter.string(from: date)
            if let price = row.pricePerLb { monthlyPrices[key, default: []].append(price) }
            if let vol = row.volumeLbs { monthlyVolume[key, default: 0] += vol }
        }

        return monthlyPrices.keys.sorted().map { month in
            let priceList = monthlyPrices[month] ?? []
            return PriceDataPoint(
                month: month,
                avgPrice: priceList.isEmpty ? 0 : priceList.reduce(0, +) / Double(priceList.count),
                minPrice: priceList.min() ?? 0,
                maxPrice: priceList.max() ?? 0,
                transactionCount: priceList.count,
                volumeMLbs: Double(monthlyVolume[month] ?? 0) / 1_000_000.0
            )
        }
    }

    // MARK: - Buyers
    func getBuyers(cropYear: Int? = nil, limit: Int = 20) async throws -> [BuyerData] {
        let year = cropYear ?? currentCropYear()
        let rows = try await fetchRows(cropYear: year, select: "buyer_name,volume_lbs,price_per_lb,destination_country")

        var buyerVolumes: [String: Int64] = [:]
        var buyerPrices: [String: [Double]] = [:]
        var buyerCountries: [String: Set<String>] = [:]
        var buyerTxCount: [String: Int] = [:]

        for row in rows {
            guard let buyer = row.buyerName else { continue }
            if let vol = row.volumeLbs { buyerVolumes[buyer, default: 0] += vol }
            if let price = row.pricePerLb { buyerPrices[buyer, default: []].append(price) }
            if let country = row.destinationCountry { buyerCountries[buyer, default: Set()].insert(country) }
            buyerTxCount[buyer, default: 0] += 1
        }

        let totalVolume = buyerVolumes.values.reduce(0, +)
        let sorted = buyerVolumes.sorted { $0.value > $1.value }.prefix(limit)

        return sorted.enumerated().map { (index, entry) in
            let prices = buyerPrices[entry.key] ?? []
            return BuyerData(
                rank: index + 1,
                buyerName: entry.key,
                volumeMLbs: Double(entry.value) / 1_000_000.0,
                avgPrice: prices.isEmpty ? nil : prices.reduce(0, +) / Double(prices.count),
                marketSharePct: totalVolume > 0 ? Double(entry.value) / Double(totalVolume) * 100 : 0,
                transactionCount: buyerTxCount[entry.key] ?? 0,
                destinationCountries: Array(buyerCountries[entry.key] ?? Set())
            )
        }
    }

    // MARK: - Handlers
    func getHandlers(cropYear: Int? = nil, limit: Int = 20) async throws -> [HandlerData] {
        let year = cropYear ?? currentCropYear()
        let rows = try await fetchRows(cropYear: year, select: "handler_name,volume_lbs,price_per_lb,variety")

        var handlerVolumes: [String: Int64] = [:]
        var handlerPrices: [String: [Double]] = [:]
        var handlerVarieties: [String: Set<String>] = [:]
        var handlerTxCount: [String: Int] = [:]

        for row in rows {
            guard let handler = row.handlerName else { continue }
            if let vol = row.volumeLbs { handlerVolumes[handler, default: 0] += vol }
            if let price = row.pricePerLb { handlerPrices[handler, default: []].append(price) }
            if let variety = row.variety { handlerVarieties[handler, default: Set()].insert(variety) }
            handlerTxCount[handler, default: 0] += 1
        }

        let totalVolume = handlerVolumes.values.reduce(0, +)
        let sorted = handlerVolumes.sorted { $0.value > $1.value }.prefix(limit)

        return sorted.enumerated().map { (index, entry) in
            let prices = handlerPrices[entry.key] ?? []
            return HandlerData(
                rank: index + 1,
                handlerName: entry.key,
                volumeMLbs: Double(entry.value) / 1_000_000.0,
                avgPrice: prices.isEmpty ? nil : prices.reduce(0, +) / Double(prices.count),
                marketSharePct: totalVolume > 0 ? Double(entry.value) / Double(totalVolume) * 100 : 0,
                transactionCount: handlerTxCount[entry.key] ?? 0,
                varieties: Array(handlerVarieties[entry.key] ?? Set())
            )
        }
    }

    // MARK: - Varieties
    func getVarieties(cropYear: Int? = nil) async throws -> [VarietyData] {
        let year = cropYear ?? currentCropYear()
        let rows = try await fetchRows(cropYear: year, select: "variety,volume_lbs,price_per_lb")

        var varietyVolumes: [String: Int64] = [:]
        var varietyPrices: [String: [Double]] = [:]
        var varietyTxCount: [String: Int] = [:]

        for row in rows {
            guard let variety = row.variety else { continue }
            if let vol = row.volumeLbs { varietyVolumes[variety, default: 0] += vol }
            if let price = row.pricePerLb { varietyPrices[variety, default: []].append(price) }
            varietyTxCount[variety, default: 0] += 1
        }

        let totalVolume = varietyVolumes.values.reduce(0, +)

        return varietyVolumes.sorted { $0.value > $1.value }.map { entry in
            let prices = varietyPrices[entry.key] ?? []
            let sorted = prices.sorted()
            let median = sorted.isEmpty ? nil : (sorted.count % 2 == 0 ? (sorted[sorted.count/2 - 1] + sorted[sorted.count/2]) / 2 : sorted[sorted.count/2])
            return VarietyData(
                variety: entry.key,
                volumeMLbs: Double(entry.value) / 1_000_000.0,
                marketSharePct: totalVolume > 0 ? Double(entry.value) / Double(totalVolume) * 100 : 0,
                avgPrice: prices.isEmpty ? nil : prices.reduce(0, +) / Double(prices.count),
                minPrice: prices.min(),
                maxPrice: prices.max(),
                medianPrice: median,
                transactionCount: varietyTxCount[entry.key] ?? 0
            )
        }
    }

    // MARK: - Destinations
    func getDestinations(cropYear: Int? = nil, limit: Int = 30) async throws -> [DestinationData] {
        let year = cropYear ?? currentCropYear()
        let rows = try await fetchRows(cropYear: year, select: "destination_country,volume_lbs,price_per_lb,variety")

        var countryVolumes: [String: Int64] = [:]
        var countryPrices: [String: [Double]] = [:]
        var countryVarieties: [String: Set<String>] = [:]
        var countryTxCount: [String: Int] = [:]

        for row in rows {
            guard let country = row.destinationCountry else { continue }
            if let vol = row.volumeLbs { countryVolumes[country, default: 0] += vol }
            if let price = row.pricePerLb { countryPrices[country, default: []].append(price) }
            if let variety = row.variety { countryVarieties[country, default: Set()].insert(variety) }
            countryTxCount[country, default: 0] += 1
        }

        let totalVolume = countryVolumes.values.reduce(0, +)
        let sorted = countryVolumes.sorted { $0.value > $1.value }.prefix(limit)

        return sorted.enumerated().map { (index, entry) in
            let prices = countryPrices[entry.key] ?? []
            return DestinationData(
                rank: index + 1,
                country: entry.key,
                volumeMLbs: Double(entry.value) / 1_000_000.0,
                marketSharePct: totalVolume > 0 ? Double(entry.value) / Double(totalVolume) * 100 : 0,
                avgPrice: prices.isEmpty ? nil : prices.reduce(0, +) / Double(prices.count),
                transactionCount: countryTxCount[entry.key] ?? 0,
                topVarieties: Array(countryVarieties[entry.key] ?? Set()).prefix(5).map { $0 }
            )
        }
    }

    // MARK: - Velocity
    func getVelocity(cropYear: Int? = nil, country: String? = nil) async throws -> [VelocityDataPoint] {
        let year = cropYear ?? currentCropYear()
        let rows = try await fetchRows(cropYear: year, select: "created_at,volume_lbs")

        let calendar = Calendar.current
        var weeklyVolume: [String: (volume: Int64, count: Int)] = [:]

        for row in rows {
            guard let dateStr = row.createdAt, let date = parseDate(dateStr) else { continue }
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            let key = df.string(from: weekStart)
            let vol = row.volumeLbs ?? 0
            let existing = weeklyVolume[key] ?? (0, 0)
            weeklyVolume[key] = (existing.volume + vol, existing.count + 1)
        }

        let sortedWeeks = weeklyVolume.keys.sorted()
        var result: [VelocityDataPoint] = []
        for (i, week) in sortedWeeks.enumerated() {
            let data = weeklyVolume[week]!
            let recentWeeks = sortedWeeks[max(0, i-3)...i]
            let movingAvg = recentWeeks.map { Double(weeklyVolume[$0]!.volume) / 1_000_000.0 }.reduce(0, +) / Double(recentWeeks.count)
            result.append(VelocityDataPoint(
                weekStart: week,
                volumeMLbs: Double(data.volume) / 1_000_000.0,
                shipmentCount: data.count,
                movingAvg4w: movingAvg
            ))
        }
        return result
    }

    // MARK: - Grades
    func getGrades(cropYear: Int? = nil, variety: String? = nil) async throws -> [GradeData] {
        let year = cropYear ?? currentCropYear()
        let rows = try await fetchRows(cropYear: year, select: "grade,volume_lbs,price_per_lb")

        var gradeVolumes: [String: Int64] = [:]
        var gradePrices: [String: [Double]] = [:]
        var gradeTxCount: [String: Int] = [:]

        for row in rows {
            let grade = row.grade ?? "Ungraded"
            if let vol = row.volumeLbs { gradeVolumes[grade, default: 0] += vol }
            if let price = row.pricePerLb { gradePrices[grade, default: []].append(price) }
            gradeTxCount[grade, default: 0] += 1
        }

        let totalVolume = gradeVolumes.values.reduce(0, +)

        return gradeVolumes.sorted { $0.value > $1.value }.map { entry in
            let prices = gradePrices[entry.key] ?? []
            return GradeData(
                grade: entry.key,
                volumeMLbs: Double(entry.value) / 1_000_000.0,
                sharePct: totalVolume > 0 ? Double(entry.value) / Double(totalVolume) * 100 : 0,
                avgPrice: prices.isEmpty ? nil : prices.reduce(0, +) / Double(prices.count),
                transactionCount: gradeTxCount[entry.key] ?? 0
            )
        }
    }

    // MARK: - Compliance
    func getCompliance(cropYear: Int? = nil) async throws -> ComplianceData {
        let year = cropYear ?? currentCropYear()
        let rows = try await fetchRows(cropYear: year, select: "grade,handler_name,variety")

        let totalRecords = rows.count
        let gradedRecords = rows.filter { $0.grade != nil && !($0.grade?.isEmpty ?? true) }.count

        var handlerTotal: [String: Int] = [:]
        var handlerGraded: [String: Int] = [:]
        var varietyTotal: [String: Int] = [:]
        var varietyGraded: [String: Int] = [:]

        for row in rows {
            if let handler = row.handlerName {
                handlerTotal[handler, default: 0] += 1
                if let grade = row.grade, !grade.isEmpty { handlerGraded[handler, default: 0] += 1 }
            }
            if let variety = row.variety {
                varietyTotal[variety, default: 0] += 1
                if let grade = row.grade, !grade.isEmpty { varietyGraded[variety, default: 0] += 1 }
            }
        }

        return ComplianceData(
            overall: ComplianceOverall(
                totalRecords: totalRecords,
                gradedRecords: gradedRecords,
                ungradedRecords: totalRecords - gradedRecords,
                complianceRatePct: totalRecords > 0 ? Double(gradedRecords) / Double(totalRecords) * 100 : 0
            ),
            byHandler: handlerTotal.map { entry in
                HandlerCompliance(
                    handlerName: entry.key,
                    totalRecords: entry.value,
                    gradedRecords: handlerGraded[entry.key] ?? 0,
                    complianceRatePct: entry.value > 0 ? Double(handlerGraded[entry.key] ?? 0) / Double(entry.value) * 100 : 0
                )
            }.sorted { $0.complianceRatePct > $1.complianceRatePct },
            byVariety: varietyTotal.map { entry in
                VarietyCompliance(
                    variety: entry.key,
                    totalRecords: entry.value,
                    gradedRecords: varietyGraded[entry.key] ?? 0,
                    complianceRatePct: entry.value > 0 ? Double(varietyGraded[entry.key] ?? 0) / Double(entry.value) * 100 : 0
                )
            }.sorted { $0.complianceRatePct > $1.complianceRatePct }
        )
    }

    // MARK: - Alerts (via Supabase PostgREST)
    func getAlerts() async throws -> [UserAlert] {
        return try await supabase.query(
            table: "user_alerts",
            order: "created_at.desc"
        )
    }

    func createAlert(_ alert: CreateAlertRequest) async throws -> UserAlert {
        // Use SupabaseService for insert
        let url = URL(string: "\(SupabaseConfig.restURL)/user_alerts")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        if let token = KeychainService.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder().encode(alert)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode < 300 else {
            throw APIError.serverError("Failed to create alert")
        }
        let results = try JSONDecoder().decode([UserAlert].self, from: data)
        guard let created = results.first else {
            throw APIError.serverError("No alert returned")
        }
        return created
    }

    func deleteAlert(id: String) async throws {
        let url = URL(string: "\(SupabaseConfig.restURL)/user_alerts?id=eq.\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        if let token = KeychainService.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let _ = try await URLSession.shared.data(for: request)
    }

    // MARK: - Utility
    private func currentCropYear() -> Int {
        let now = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        return month >= 8 ? year : year - 1
    }
}
