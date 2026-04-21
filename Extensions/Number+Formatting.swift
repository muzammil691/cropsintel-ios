import Foundation

extension Double {
    var formattedVolume: String {
        if self >= 1000 {
            return String(format: "%.1fB lbs", self / 1000)
        }
        return String(format: "%.2fM lbs", self)
    }

    var formattedPrice: String {
        return String(format: "$%.2f/lb", self)
    }

    var formattedPercent: String {
        let sign = self >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, self)
    }

    var formattedSharePercent: String {
        return String(format: "%.1f%%", self)
    }
}

extension Int {
    var formattedCount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
