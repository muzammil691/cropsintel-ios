import Foundation

// MARK: - Position Report
struct PositionReport: Codable, Identifiable {
    let id: Int
    let createdAt: String
    let month: String?
    let cropYear: Int?
    let cropReceipts: Double?
    let domesticYtd: Double?
    let exportYtd: Double?
    let marketableSupply: Double?
    let newContracts: Double?
    let openingInventory: Double?
    let totalSupply: Double?
    let uncommitted: Double?
    let totalCommitments: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case month
        case cropYear = "crop_year"
        case cropReceipts = "crop_receipts"
        case domesticYtd = "domestic_ytd"
        case exportYtd = "export_ytd"
        case marketableSupply = "marketable_supply"
        case newContracts = "new_contracts"
        case openingInventory = "opening_inventory"
        case totalSupply = "total_supply"
        case uncommitted
        case totalCommitments = "total_commitments"
    }

    /// Format month field as "MMM-YYYY" display string
    var displayMonth: String {
        guard let month = month else { return "N/A" }
        // If already formatted, return as-is
        if month.contains("-") && month.count <= 8 {
            return month.capitalized
        }
        // Try to parse ISO date
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withFullDate]
        if let date = isoFormatter.date(from: month) {
            let df = DateFormatter()
            df.dateFormat = "MMM-yyyy"
            return df.string(from: date)
        }
        // Try other date format
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        if let date = df.date(from: month) {
            df.dateFormat = "MMM-yyyy"
            return df.string(from: date)
        }
        return month
    }

    /// Convert raw values to M lbs
    var cropReceiptsMLbs: Double { (cropReceipts ?? 0) / 1_000_000 }
    var domesticYtdMLbs: Double { (domesticYtd ?? 0) / 1_000_000 }
    var exportYtdMLbs: Double { (exportYtd ?? 0) / 1_000_000 }
    var marketableSupplyMLbs: Double { (marketableSupply ?? 0) / 1_000_000 }
    var newContractsMLbs: Double { (newContracts ?? 0) / 1_000_000 }
    var uncommittedMLbs: Double { (uncommitted ?? 0) / 1_000_000 }
    var totalSupplyMLbs: Double { (totalSupply ?? 0) / 1_000_000 }
    var totalCommitmentsMLbs: Double { (totalCommitments ?? 0) / 1_000_000 }
}

// MARK: - News Article
struct NewsArticle: Codable, Identifiable {
    let id: Int
    let title: String?
    let summary: String?
    let publishedAt: String?
    let source: String?
    let url: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case id, title, summary, source, url, status
        case publishedAt = "published_at"
    }

    var displayDate: String {
        guard let publishedAt = publishedAt else { return "" }
        // Try ISO 8601 with fractional seconds
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: publishedAt) {
            let df = DateFormatter()
            df.dateFormat = "MMM d, yyyy"
            return df.string(from: date)
        }
        // Try without fractional seconds
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: publishedAt) {
            let df = DateFormatter()
            df.dateFormat = "MMM d, yyyy"
            return df.string(from: date)
        }
        return publishedAt
    }
}
