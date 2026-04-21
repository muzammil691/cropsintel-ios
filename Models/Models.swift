import Foundation

// MARK: - API Response Wrapper
struct ApiResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let meta: [String: AnyCodable]?
    let error: ApiError?
}

struct ApiError: Codable {
    let code: String
    let message: String
}

// MARK: - Auth Models
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct AuthTokens: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

struct AuthUser: Codable {
    let id: String
    let email: String
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, email
        case createdAt = "created_at"
    }
}

struct LoginResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String
    let user: AuthUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case user
    }
}

// MARK: - Market Summary
struct MarketSummary: Codable, Identifiable {
    var id: String { "\(cropYear)" }
    let cropYear: Int
    let totalVolumeMLbs: Double
    let avgPricePerLb: Double
    let volumeChangePct: Double
    let priceChangePct: Double
    let uniqueVarieties: Int
    let uniqueDestinations: Int
    let uniqueBuyers: Int
    let uniqueHandlers: Int
    let totalTransactions: Int

    enum CodingKeys: String, CodingKey {
        case cropYear = "crop_year"
        case totalVolumeMLbs = "total_volume_mlbs"
        case avgPricePerLb = "avg_price_per_lb"
        case volumeChangePct = "volume_change_pct"
        case priceChangePct = "price_change_pct"
        case uniqueVarieties = "unique_varieties"
        case uniqueDestinations = "unique_destinations"
        case uniqueBuyers = "unique_buyers"
        case uniqueHandlers = "unique_handlers"
        case totalTransactions = "total_transactions"
    }
}

// MARK: - Volume Data
struct VolumeDataPoint: Codable, Identifiable {
    var id: String { period }
    let period: String
    let volumeMLbs: Double
    let volumeLbs: Int64

    enum CodingKeys: String, CodingKey {
        case period
        case volumeMLbs = "volume_mlbs"
        case volumeLbs = "volume_lbs"
    }
}

// MARK: - Price Data
struct PriceDataPoint: Codable, Identifiable {
    var id: String { month }
    let month: String
    let avgPrice: Double
    let minPrice: Double
    let maxPrice: Double
    let transactionCount: Int
    let volumeMLbs: Double

    enum CodingKeys: String, CodingKey {
        case month
        case avgPrice = "avg_price"
        case minPrice = "min_price"
        case maxPrice = "max_price"
        case transactionCount = "transaction_count"
        case volumeMLbs = "volume_mlbs"
    }
}

// MARK: - Buyer Data
struct BuyerData: Codable, Identifiable {
    var id: String { buyerName }
    let rank: Int
    let buyerName: String
    let volumeMLbs: Double
    let avgPrice: Double?
    let marketSharePct: Double
    let transactionCount: Int
    let destinationCountries: [String]

    enum CodingKeys: String, CodingKey {
        case rank
        case buyerName = "buyer_name"
        case volumeMLbs = "volume_mlbs"
        case avgPrice = "avg_price"
        case marketSharePct = "market_share_pct"
        case transactionCount = "transaction_count"
        case destinationCountries = "destination_countries"
    }
}

// MARK: - Handler Data
struct HandlerData: Codable, Identifiable {
    var id: String { handlerName }
    let rank: Int
    let handlerName: String
    let volumeMLbs: Double
    let avgPrice: Double?
    let marketSharePct: Double
    let transactionCount: Int
    let varieties: [String]

    enum CodingKeys: String, CodingKey {
        case rank
        case handlerName = "handler_name"
        case volumeMLbs = "volume_mlbs"
        case avgPrice = "avg_price"
        case marketSharePct = "market_share_pct"
        case transactionCount = "transaction_count"
        case varieties
    }
}

// MARK: - Variety Data
struct VarietyData: Codable, Identifiable {
    var id: String { variety }
    let variety: String
    let volumeMLbs: Double
    let marketSharePct: Double
    let avgPrice: Double?
    let minPrice: Double?
    let maxPrice: Double?
    let medianPrice: Double?
    let transactionCount: Int

    enum CodingKeys: String, CodingKey {
        case variety
        case volumeMLbs = "volume_mlbs"
        case marketSharePct = "market_share_pct"
        case avgPrice = "avg_price"
        case minPrice = "min_price"
        case maxPrice = "max_price"
        case medianPrice = "median_price"
        case transactionCount = "transaction_count"
    }
}

// MARK: - Seasonal Data
struct SeasonalDataPoint: Codable, Identifiable {
    var id: Int { month }
    let month: Int
    let monthName: String

    enum CodingKeys: String, CodingKey {
        case month
        case monthName = "month_name"
    }
}

// MARK: - Export Destination
struct DestinationData: Codable, Identifiable {
    var id: String { country }
    let rank: Int
    let country: String
    let volumeMLbs: Double
    let marketSharePct: Double
    let avgPrice: Double?
    let transactionCount: Int
    let topVarieties: [String]

    enum CodingKeys: String, CodingKey {
        case rank, country
        case volumeMLbs = "volume_mlbs"
        case marketSharePct = "market_share_pct"
        case avgPrice = "avg_price"
        case transactionCount = "transaction_count"
        case topVarieties = "top_varieties"
    }
}

// MARK: - Velocity Data
struct VelocityDataPoint: Codable, Identifiable {
    var id: String { weekStart }
    let weekStart: String
    let volumeMLbs: Double
    let shipmentCount: Int
    let movingAvg4w: Double

    enum CodingKeys: String, CodingKey {
        case weekStart = "week_start"
        case volumeMLbs = "volume_mlbs"
        case shipmentCount = "shipment_count"
        case movingAvg4w = "moving_avg_4w"
    }
}

// MARK: - Grade Data
struct GradeData: Codable, Identifiable {
    var id: String { grade }
    let grade: String
    let volumeMLbs: Double
    let sharePct: Double
    let avgPrice: Double?
    let transactionCount: Int

    enum CodingKeys: String, CodingKey {
        case grade
        case volumeMLbs = "volume_mlbs"
        case sharePct = "share_pct"
        case avgPrice = "avg_price"
        case transactionCount = "transaction_count"
    }
}

// MARK: - Compliance Data
struct ComplianceData: Codable {
    let overall: ComplianceOverall
    let byHandler: [HandlerCompliance]
    let byVariety: [VarietyCompliance]

    enum CodingKeys: String, CodingKey {
        case overall
        case byHandler = "by_handler"
        case byVariety = "by_variety"
    }
}

struct ComplianceOverall: Codable {
    let totalRecords: Int
    let gradedRecords: Int
    let ungradedRecords: Int
    let complianceRatePct: Double

    enum CodingKeys: String, CodingKey {
        case totalRecords = "total_records"
        case gradedRecords = "graded_records"
        case ungradedRecords = "ungraded_records"
        case complianceRatePct = "compliance_rate_pct"
    }
}

struct HandlerCompliance: Codable, Identifiable {
    var id: String { handlerName }
    let handlerName: String
    let totalRecords: Int
    let gradedRecords: Int
    let complianceRatePct: Double

    enum CodingKeys: String, CodingKey {
        case handlerName = "handler_name"
        case totalRecords = "total_records"
        case gradedRecords = "graded_records"
        case complianceRatePct = "compliance_rate_pct"
    }
}

struct VarietyCompliance: Codable, Identifiable {
    var id: String { variety }
    let variety: String
    let totalRecords: Int
    let gradedRecords: Int
    let complianceRatePct: Double

    enum CodingKeys: String, CodingKey {
        case variety
        case totalRecords = "total_records"
        case gradedRecords = "graded_records"
        case complianceRatePct = "compliance_rate_pct"
    }
}

// MARK: - Alert Models
struct UserAlert: Codable, Identifiable {
    let id: String
    let userId: String
    let alertType: String
    let condition: String
    let threshold: Double
    let variety: String?
    let handler: String?
    let destination: String?
    let isActive: Bool
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case alertType = "alert_type"
        case condition
        case threshold
        case variety, handler, destination
        case isActive = "is_active"
        case createdAt = "created_at"
    }
}

struct CreateAlertRequest: Codable {
    let alertType: String
    let condition: String
    let threshold: Double
    let variety: String?
    let handler: String?
    let destination: String?

    enum CodingKeys: String, CodingKey {
        case alertType = "alert_type"
        case condition
        case threshold
        case variety, handler, destination
    }
}

// MARK: - Token Response (alias for AuthTokens)
typealias TokenResponse = AuthTokens

// MARK: - AnyCodable helper
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let stringVal = try? container.decode(String.self) {
            value = stringVal
        } else if let boolVal = try? container.decode(Bool.self) {
            value = boolVal
        } else {
            value = ""
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let intVal = value as? Int {
            try container.encode(intVal)
        } else if let doubleVal = value as? Double {
            try container.encode(doubleVal)
        } else if let stringVal = value as? String {
            try container.encode(stringVal)
        } else if let boolVal = value as? Bool {
            try container.encode(boolVal)
        }
    }
}
