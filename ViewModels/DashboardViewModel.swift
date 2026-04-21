import SwiftUI
import Combine

// MARK: - Dashboard Supabase Row Models
struct AlmondDataRow: Codable {
    let id: Int?
    let createdAt: String?
    let cropYear: Int?
    let variety: String?
    let handlerName: String?
    let buyerName: String?
    let volumeLbs: Int64?
    let pricePerLb: Double?
    let destinationCountry: String?
    let grade: String?

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case cropYear = "crop_year"
        case variety
        case handlerName = "handler_name"
        case buyerName = "buyer_name"
        case volumeLbs = "volume_lbs"
        case pricePerLb = "price_per_lb"
        case destinationCountry = "destination_country"
        case grade
    }
}

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var summary: MarketSummary?
    @Published var volumeData: [VolumeDataPoint] = []
    @Published var priceData: [PriceDataPoint] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabase = SupabaseService.shared

    func loadDashboard(cropYear: Int) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Build date range for crop year (Aug 1 of cropYear to Jul 31 of cropYear+1)
                let startDate = "\(cropYear)-08-01T00:00:00Z"
                let endDate = "\(cropYear + 1)-07-31T23:59:59Z"

                // Fetch raw data from almond_data_combined
                let rows: [AlmondDataRow] = try await supabase.query(
                    table: "almond_data_combined",
                    select: "*",
                    filters: [
                        "created_at": "gte.\(startDate)",
                    ]
                )

                // Filter by end date client-side (PostgREST duplicate key limitation)
                let isoFormatter = ISO8601DateFormatter()
                isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let isoBasic = ISO8601DateFormatter()
                isoBasic.formatOptions = [.withInternetDateTime]

                let filteredRows = rows.filter { row in
                    guard let dateStr = row.createdAt else { return false }
                    if let d = isoFormatter.date(from: dateStr) ?? isoBasic.date(from: dateStr) {
                        let endD = isoBasic.date(from: endDate) ?? Date()
                        return d <= endD
                    }
                    return true
                }

                // Compute summary from raw data
                let totalVolumeLbs = filteredRows.compactMap { $0.volumeLbs }.reduce(0, +)
                let totalVolumeMLbs = Double(totalVolumeLbs) / 1_000_000.0
                let prices = filteredRows.compactMap { $0.pricePerLb }
                let avgPrice = prices.isEmpty ? 0 : prices.reduce(0, +) / Double(prices.count)
                let uniqueVarieties = Set(filteredRows.compactMap { $0.variety }).count
                let uniqueDestinations = Set(filteredRows.compactMap { $0.destinationCountry }).count
                let uniqueBuyers = Set(filteredRows.compactMap { $0.buyerName }).count
                let uniqueHandlers = Set(filteredRows.compactMap { $0.handlerName }).count

                summary = MarketSummary(
                    cropYear: cropYear,
                    totalVolumeMLbs: totalVolumeMLbs,
                    avgPricePerLb: avgPrice,
                    volumeChangePct: 0,
                    priceChangePct: 0,
                    uniqueVarieties: uniqueVarieties,
                    uniqueDestinations: uniqueDestinations,
                    uniqueBuyers: uniqueBuyers,
                    uniqueHandlers: uniqueHandlers,
                    totalTransactions: filteredRows.count
                )

                // Compute monthly volume
                let monthFormatter = DateFormatter()
                monthFormatter.dateFormat = "yyyy-MM"

                var monthlyVolume: [String: Int64] = [:]
                var monthlyPrices: [String: [Double]] = [:]

                for row in filteredRows {
                    guard let dateStr = row.createdAt else { continue }
                    guard let parsedDate = isoFormatter.date(from: dateStr) ?? isoBasic.date(from: dateStr) else { continue }
                    let monthKey = monthFormatter.string(from: parsedDate)

                    if let vol = row.volumeLbs {
                        monthlyVolume[monthKey, default: 0] += vol
                    }
                    if let price = row.pricePerLb {
                        monthlyPrices[monthKey, default: []].append(price)
                    }
                }

                volumeData = monthlyVolume.keys.sorted().map { month in
                    VolumeDataPoint(
                        period: month,
                        volumeMLbs: Double(monthlyVolume[month] ?? 0) / 1_000_000.0,
                        volumeLbs: monthlyVolume[month] ?? 0
                    )
                }

                priceData = monthlyPrices.keys.sorted().map { month in
                    let priceList = monthlyPrices[month] ?? []
                    let avg = priceList.isEmpty ? 0 : priceList.reduce(0, +) / Double(priceList.count)
                    let minP = priceList.min() ?? 0
                    let maxP = priceList.max() ?? 0
                    return PriceDataPoint(
                        month: month,
                        avgPrice: avg,
                        minPrice: minP,
                        maxPrice: maxP,
                        transactionCount: priceList.count,
                        volumeMLbs: Double(monthlyVolume[month] ?? 0) / 1_000_000.0
                    )
                }

            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
