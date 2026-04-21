import SwiftUI
import Combine

final class AppState: ObservableObject {
    @Published var selectedTab: Tab = .dashboard
    @Published var currentCropYear: Int

    enum Tab: String, CaseIterable {
        case dashboard = "Dashboard"
        case market = "Market"
        case reports = "Reports"
        case news = "News"
        case exports = "Exports"
        case quality = "Quality"
        case alerts = "Alerts"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .dashboard: return "chart.bar.fill"
            case .market: return "chart.line.uptrend.xyaxis"
            case .reports: return "doc.text.fill"
            case .news: return "newspaper.fill"
            case .exports: return "globe"
            case .quality: return "checkmark.seal.fill"
            case .alerts: return "bell.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    init() {
        let now = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        self.currentCropYear = month >= 8 ? year : year - 1
    }
}
