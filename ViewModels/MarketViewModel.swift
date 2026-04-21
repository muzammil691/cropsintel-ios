import SwiftUI
import Combine

@MainActor
final class MarketViewModel: ObservableObject {
    @Published var buyers: [BuyerData] = []
    @Published var handlers: [HandlerData] = []
    @Published var varieties: [VarietyData] = []
    @Published var volumeData: [VolumeDataPoint] = []
    @Published var priceData: [PriceDataPoint] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedSegment: MarketSegment = .volume

    enum MarketSegment: String, CaseIterable {
        case volume = "Volume"
        case price = "Price"
        case buyers = "Buyers"
        case handlers = "Handlers"
        case varieties = "Varieties"
    }

    private let api = APIService.shared

    func loadData(cropYear: Int) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                async let buyersTask = api.getBuyers(cropYear: cropYear)
                async let handlersTask = api.getHandlers(cropYear: cropYear)
                async let varietiesTask = api.getVarieties(cropYear: cropYear)
                async let volumeTask = api.getVolumeData(cropYear: cropYear)
                async let priceTask = api.getPriceData(cropYear: cropYear)

                let (b, h, v, vol, pr) = try await (buyersTask, handlersTask, varietiesTask, volumeTask, priceTask)

                self.buyers = b
                self.handlers = h
                self.varieties = v
                self.volumeData = vol
                self.priceData = pr
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }
}
