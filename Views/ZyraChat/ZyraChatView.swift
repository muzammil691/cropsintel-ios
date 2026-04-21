import SwiftUI

struct ZyraChatView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // Zyra Avatar & Info
                    VStack(spacing: 20) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.amberAccent, Color.amberAccent.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)

                            Text("Z")
                                .font(.system(size: 44, weight: .bold))
                                .foregroundColor(.darkBackground)
                        }

                        VStack(spacing: 8) {
                            Text("Zyra AI")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            Text("Your AI Analyst for the Almond Market")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }

                    Spacer().frame(height: 40)

                    // Feature Cards
                    VStack(spacing: 12) {
                        ZyraFeatureRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Market Analysis",
                            description: "Get real-time insights on almond pricing and volume trends"
                        )
                        ZyraFeatureRow(
                            icon: "globe",
                            title: "Export Intelligence",
                            description: "Track shipment destinations and buyer activity"
                        )
                        ZyraFeatureRow(
                            icon: "bell.badge",
                            title: "Smart Alerts",
                            description: "Set up custom notifications for market conditions"
                        )
                        ZyraFeatureRow(
                            icon: "doc.text.magnifyingglass",
                            title: "Position Reports",
                            description: "Analyze USDA position report data instantly"
                        )
                    }
                    .padding(.horizontal, 24)

                    Spacer()

                    // Connect Button
                    VStack(spacing: 12) {
                        Button(action: openWhatsApp) {
                            HStack(spacing: 12) {
                                Image(systemName: "message.fill")
                                    .font(.system(size: 20))
                                Text("Chat with Zyra on WhatsApp")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#25D366"), Color(hex: "#128C7E")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(14)
                        }

                        Text("Chat with Zyra — your AI analyst for the almond market")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Zyra AI")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.textSecondary)
                    }
                }
            }
        }
    }

    private func openWhatsApp() {
        let phoneNumber = "+12345622692"
        let message = "Hi Zyra! I'd like help with almond market analysis."
        let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://wa.me/\(phoneNumber.replacingOccurrences(of: "+", with: ""))?text=\(encodedMessage)"

        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Feature Row
struct ZyraFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.amberAccent)
                .frame(width: 36, height: 36)
                .background(Color.amberAccent.opacity(0.15))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.darkSurface)
        .cornerRadius(12)
    }
}

// MARK: - Floating Chat Bubble (for Dashboard)
struct ZyraChatBubble: View {
    @State private var showZyraChat = false

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: { showZyraChat = true }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.amberAccent, Color.amberAccent.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .shadow(color: Color.amberAccent.opacity(0.4), radius: 12, x: 0, y: 4)

                        Text("Z")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.darkBackground)
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showZyraChat) {
            ZyraChatView()
        }
    }
}
