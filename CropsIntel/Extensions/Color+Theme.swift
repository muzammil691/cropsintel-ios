import SwiftUI

extension Color {
    // CropsIntel Brand Colors
    static let tealPrimary = Color(hex: "#10B981")
    static let amberAccent = Color(hex: "#F59E0B")
    static let darkBackground = Color(hex: "#1a1a2e")
    static let darkSurface = Color(hex: "#16213e")
    static let darkCard = Color(hex: "#0f3460")
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "#94A3B8")

    // Chart Colors
    static let chartColors: [Color] = [
        Color(hex: "#10B981"),
        Color(hex: "#F59E0B"),
        Color(hex: "#3B82F6"),
        Color(hex: "#EF4444"),
        Color(hex: "#8B5CF6"),
        Color(hex: "#EC4899"),
        Color(hex: "#14B8A6"),
        Color(hex: "#F97316"),
    ]

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
