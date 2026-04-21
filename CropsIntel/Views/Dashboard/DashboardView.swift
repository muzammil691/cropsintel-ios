import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                if viewModel.isLoading && viewModel.summary == nil {
                    LoadingView()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Dashboard")
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    Text("Almond Market Intelligence by MAXONS")
                                        .font(.subheadline)
                                        .foregroundColor(.textSecondary)
                                }
                                Spacer()
                                CropYearPicker(
                                    selectedYear: $appState.currentCropYear,
                                    years: Array((2020...2025).reversed())
                                )
                            }
                            .padding(.horizontal)

                            if let error = viewModel.errorMessage {
                                ErrorBanner(message: error) {
                                    viewModel.loadDashboard(cropYear: appState.currentCropYear)
                                }
                                .padding(.horizontal)
                            }

                            // KPI Grid
                            if let summary = viewModel.summary {
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                ], spacing: 12) {
                                    KPICard(
                                        title: "Total Volume",
                                        value: summary.totalVolumeMLbs.formattedVolume,
                                        change: summary.volumeChangePct.formattedPercent,
                                        icon: "shippingbox.fill"
                                    )
                                    KPICard(
                                        title: "Avg Price",
                                        value: summary.avgPricePerLb.formattedPrice,
                                        change: summary.priceChangePct.formattedPercent,
                                        icon: "dollarsign.circle.fill",
                                        color: .amberAccent
                                    )
                                    KPICard(
                                        title: "Transactions",
                                        value: summary.totalTransactions.formattedCount,
                                        icon: "arrow.left.arrow.right"
                                    )
                                    KPICard(
                                        title: "Destinations",
                                        value: "\(summary.uniqueDestinations)",
                                        icon: "globe",
                                        color: .blue
                                    )
                                    KPICard(
                                        title: "Varieties",
                                        value: "\(summary.uniqueVarieties)",
                                        icon: "leaf.fill",
                                        color: .green
                                    )
                                    KPICard(
                                        title: "Active Buyers",
                                        value: "\(summary.uniqueBuyers)",
                                        icon: "person.2.fill",
                                        color: .purple
                                    )
                                }
                                .padding(.horizontal)
                            }

                            // Volume Chart
                            if !viewModel.volumeData.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    SectionHeader(title: "Monthly Volume", subtitle: "M lbs shipped per month")
                                        .padding(.horizontal)

                                    Chart(viewModel.volumeData) { point in
                                        BarMark(
                                            x: .value("Month", point.period),
                                            y: .value("Volume", point.volumeMLbs)
                                        )
                                        .foregroundStyle(Color.tealPrimary.gradient)
                                        .cornerRadius(4)
                                    }
                                    .chartXAxis {
                                        AxisMarks(values: .automatic) { value in
                                            AxisValueLabel {
                                                if let str = value.as(String.self) {
                                                    Text(String(str.suffix(2)))
                                                        .font(.caption2)
                                                        .foregroundColor(.textSecondary)
                                                }
                                            }
                                        }
                                    }
                                    .chartYAxis {
                                        AxisMarks { value in
                                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                                                .foregroundStyle(Color.gray.opacity(0.3))
                                            AxisValueLabel()
                                                .foregroundStyle(Color.textSecondary)
                                        }
                                    }
                                    .frame(height: 200)
                                    .padding(.horizontal)
                                }
                                .padding()
                                .background(Color.darkSurface)
                                .cornerRadius(16)
                                .padding(.horizontal)
                            }

                            // Price Trend Chart
                            if !viewModel.priceData.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    SectionHeader(title: "Price Trends", subtitle: "Weighted avg $/lb")
                                        .padding(.horizontal)

                                    Chart(viewModel.priceData) { point in
                                        LineMark(
                                            x: .value("Month", point.month),
                                            y: .value("Price", point.avgPrice)
                                        )
                                        .foregroundStyle(Color.amberAccent)
                                        .interpolationMethod(.catmullRom)

                                        AreaMark(
                                            x: .value("Month", point.month),
                                            yStart: .value("Min", point.minPrice),
                                            yEnd: .value("Max", point.maxPrice)
                                        )
                                        .foregroundStyle(Color.amberAccent.opacity(0.1))
                                    }
                                    .chartXAxis {
                                        AxisMarks(values: .automatic) { value in
                                            AxisValueLabel {
                                                if let str = value.as(String.self) {
                                                    Text(String(str.suffix(2)))
                                                        .font(.caption2)
                                                        .foregroundColor(.textSecondary)
                                                }
                                            }
                                        }
                                    }
                                    .chartYAxis {
                                        AxisMarks { _ in
                                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                                                .foregroundStyle(Color.gray.opacity(0.3))
                                            AxisValueLabel()
                                                .foregroundStyle(Color.textSecondary)
                                        }
                                    }
                                    .frame(height: 200)
                                    .padding(.horizontal)
                                }
                                .padding()
                                .background(Color.darkSurface)
                                .cornerRadius(16)
                                .padding(.horizontal)
                            }

                            Spacer(minLength: 80)
                        }
                        .padding(.top)
                    }
                    .refreshable {
                        viewModel.loadDashboard(cropYear: appState.currentCropYear)
                    }
                }

                // Floating Zyra Chat Bubble
                ZyraChatBubble()
            }
            .navigationBarHidden(true)
            .onAppear {
                if viewModel.summary == nil {
                    viewModel.loadDashboard(cropYear: appState.currentCropYear)
                }
            }
            .onChange(of: appState.currentCropYear) { newYear in
                viewModel.loadDashboard(cropYear: newYear)
            }
        }
    }
}
