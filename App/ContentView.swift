import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: authViewModel.isAuthenticated)
    }
}

struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "chart.bar.fill")
                }
                .tag(AppState.Tab.dashboard)

            MarketOverviewView()
                .tabItem {
                    Label("Market", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(AppState.Tab.market)

            PositionReportsView()
                .tabItem {
                    Label("Reports", systemImage: "doc.text.fill")
                }
                .tag(AppState.Tab.reports)

            NewsFeedView()
                .tabItem {
                    Label("News", systemImage: "newspaper.fill")
                }
                .tag(AppState.Tab.news)

            MoreTabView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle.fill")
                }
                .tag(AppState.Tab.exports)
        }
        .tint(Color.amberAccent)
    }
}

// MARK: - More Tab (Exports, Quality, Alerts, Settings)
struct MoreTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("More")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text("Almond Market Intelligence by MAXONS")
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top)

                        // Navigation Links
                        NavigationLink(destination: ExportsView()) {
                            MoreMenuItem(icon: "globe", title: "Exports", subtitle: "Destination & velocity analysis", color: .blue)
                        }

                        NavigationLink(destination: QualityView()) {
                            MoreMenuItem(icon: "checkmark.seal.fill", title: "Quality", subtitle: "Grade distribution & compliance", color: .green)
                        }

                        NavigationLink(destination: AlertsView()) {
                            MoreMenuItem(icon: "bell.fill", title: "Alerts", subtitle: "Price & volume notifications", color: .amberAccent)
                        }

                        NavigationLink(destination: ZyraChatView()) {
                            MoreMenuItem(icon: "message.fill", title: "Zyra AI", subtitle: "Chat with your AI market analyst", color: Color(hex: "#25D366"))
                        }

                        NavigationLink(destination: SettingsView()) {
                            MoreMenuItem(icon: "gearshape.fill", title: "Settings", subtitle: "Preferences & account", color: .textSecondary)
                        }

                        Spacer(minLength: 80)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct MoreMenuItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.15))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .padding(14)
        .background(Color.darkSurface)
        .cornerRadius(14)
        .padding(.horizontal)
    }
}
