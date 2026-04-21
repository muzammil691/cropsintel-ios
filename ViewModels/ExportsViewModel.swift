import SwiftUI
import Combine

@MainActor
final class ExportsViewModel: ObservableObject {
    @Published var destinations: [DestinationData] = []
    @Published var velocity: [VelocityDataPoint] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedCountry: String?

    private let api = APIService.shared

    func loadData(cropYear: Int) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                async let destTask = api.getDestinations(cropYear: cropYear)
                async let velTask = api.getVelocity(cropYear: cropYear)

                let (d, v) = try await (destTask, velTask)

                self.destinations = d
                self.velocity = v
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }

    func loadVelocityForCountry(_ country: String, cropYear: Int) {
        selectedCountry = country
        Task {
            do {
                self.velocity = try await api.getVelocity(cropYear: cropYear, country: country)
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
