import SwiftUI
import Combine

@MainActor
final class AlertsViewModel: ObservableObject {
    @Published var alerts: [UserAlert] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showCreateSheet = false

    // Create alert form
    @Published var alertType: String = "price_above"
    @Published var condition: String = ""
    @Published var threshold: String = ""
    @Published var variety: String = ""
    @Published var handler: String = ""
    @Published var destination: String = ""

    private let api = APIService.shared

    let alertTypes = [
        ("price_above", "Price Above"),
        ("price_below", "Price Below"),
        ("volume_above", "Volume Above"),
        ("volume_below", "Volume Below"),
    ]

    func loadAlerts() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                self.alerts = try await api.getAlerts()
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }

    func createAlert() {
        guard !condition.isEmpty, let thresholdValue = Double(threshold) else {
            errorMessage = "Please fill in all required fields"
            return
        }

        isLoading = true

        Task {
            do {
                let request = CreateAlertRequest(
                    alertType: alertType,
                    condition: condition,
                    threshold: thresholdValue,
                    variety: variety.isEmpty ? nil : variety,
                    handler: handler.isEmpty ? nil : handler,
                    destination: destination.isEmpty ? nil : destination
                )
                let newAlert = try await api.createAlert(request)
                self.alerts.insert(newAlert, at: 0)
                self.showCreateSheet = false
                resetForm()
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }

    func deleteAlert(_ alert: UserAlert) {
        Task {
            do {
                try await api.deleteAlert(id: alert.id)
                self.alerts.removeAll { $0.id == alert.id }
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func resetForm() {
        alertType = "price_above"
        condition = ""
        threshold = ""
        variety = ""
        handler = ""
        destination = ""
    }
}
