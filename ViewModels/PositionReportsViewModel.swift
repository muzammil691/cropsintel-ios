import SwiftUI
import Combine

@MainActor
final class PositionReportsViewModel: ObservableObject {
    @Published var reports: [PositionReport] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedCropYear: Int?

    private let supabase = SupabaseService.shared

    var filteredReports: [PositionReport] {
        var result = reports

        if let year = selectedCropYear {
            result = result.filter { $0.cropYear == year }
        }

        if !searchText.isEmpty {
            result = result.filter { report in
                let monthMatch = report.displayMonth.localizedCaseInsensitiveContains(searchText)
                let yearMatch = "\(report.cropYear ?? 0)".contains(searchText)
                return monthMatch || yearMatch
            }
        }

        return result
    }

    var availableCropYears: [Int] {
        let years = Set(reports.compactMap { $0.cropYear })
        return years.sorted(by: >)
    }

    func loadReports() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let result: [PositionReport] = try await supabase.query(
                    table: "position_reports",
                    select: "*",
                    order: "created_at.desc"
                )
                reports = result
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
