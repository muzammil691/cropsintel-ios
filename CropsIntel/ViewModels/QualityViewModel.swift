import SwiftUI
import Combine

@MainActor
final class QualityViewModel: ObservableObject {
    @Published var grades: [GradeData] = []
    @Published var compliance: ComplianceData?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api = APIService.shared

    func loadData(cropYear: Int) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                async let gradesTask = api.getGrades(cropYear: cropYear)
                async let complianceTask = api.getCompliance(cropYear: cropYear)

                let (g, c) = try await (gradesTask, complianceTask)

                self.grades = g
                self.compliance = c
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }
}
