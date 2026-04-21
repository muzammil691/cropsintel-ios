import SwiftUI
import Charts

struct MarketOverviewView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = MarketViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                if viewModel.isLoading && viewModel.buyers.isEmpty {
                    LoadingView()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header
                            HStack {
                                Text("Market Overview")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Spacer()
                                CropYearPicker(
                                    selectedYear: $appState.currentCropYear,
                                    years: Array((2020...2025).reversed())
                                )
                            }
                            .padding(.horizontal)

                            if let error = viewModel.errorMessage {
                                ErrorBanner(message: error) {
                                    viewModel.loadData(cropYear: appState.currentCropYear)
                                }
                                .padding(.horizontal)
                            }

                            // Segment Picker
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(MarketViewModel.MarketSegment.allCases, id: \.self) { segment in
                                        Button(action: { viewModel.selectedSegment = segment }) {
                                            Text(segment.rawValue)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(
                                                    viewModel.selectedSegment == segment
                                                        ? Color.tealPrimary
                                                        : Color.darkSurface
                                                )
                                                .foregroundColor(
                                                    viewModel.selectedSegment == segment
                                                        ? .white
                                                        : .textSecondary
                                                )
                                                .cornerRadius(20)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }

                            // Content based on segment
                            switch viewModel.selectedSegment {
                            case .volume:
                                volumeSection
                            case .price:
                                priceSection
                            case .buyers:
                                buyersSection
                            case .handlers:
                                handlersSection
                            case .varieties:
                                varietiesSection
                            }

                            Spacer(minLength: 80)
                        }
                        .padding(.top)
                    }
                    .refreshable {
                        viewModel.loadData(cropYear: appState.currentCropYear)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                if viewModel.buyers.isEmpty {
                    viewModel.loadData(cropYear: appState.currentCropYear)
                }
            }
            .onChange(of: appState.currentCropYear) { newYear in
                viewModel.loadData(cropYear: newYear)
            }
        }
    }

    // MARK: - Volume Section
    private var volumeSection: some View {
        VStack(spacing: 16) {
            if !viewModel.volumeData.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Volume Trends", subtitle: "Monthly shipment volume in M lbs")

                    Chart(viewModel.volumeData) { point in
                        BarMark(
                            x: .value("Period", point.period),
                            y: .value("Volume", point.volumeMLbs)
                        )
                        .foregroundStyle(Color.tealPrimary.gradient)
                        .cornerRadius(4)
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                                .foregroundStyle(Color.gray.opacity(0.3))
                            AxisValueLabel().foregroundStyle(Color.textSecondary)
                        }
                    }
                    .frame(height: 250)
                }
                .padding()
                .background(Color.darkSurface)
                .cornerRadius(16)
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Price Section
    private var priceSection: some View {
        VStack(spacing: 16) {
            if !viewModel.priceData.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Price Trends", subtitle: "Weighted average price $/lb")

                    Chart(viewModel.priceData) { point in
                        LineMark(
                            x: .value("Month", point.month),
                            y: .value("Avg", point.avgPrice)
                        )
                        .foregroundStyle(Color.amberAccent)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2))

                        PointMark(
                            x: .value("Month", point.month),
                            y: .value("Avg", point.avgPrice)
                        )
                        .foregroundStyle(Color.amberAccent)
                        .symbolSize(30)
                    }
                    .frame(height: 250)
                }
                .padding()
                .background(Color.darkSurface)
                .cornerRadius(16)
                .padding(.horizontal)

                // Price table
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(title: "Monthly Detail")

                    ForEach(viewModel.priceData) { point in
                        HStack {
                            Text(point.month)
                                .font(.subheadline)
                                .foregroundColor(.white)
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(point.avgPrice.formattedPrice)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.amberAccent)
                                Text("\(point.minPrice.formattedPrice) - \(point.maxPrice.formattedPrice)")
                                    .font(.caption2)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .padding(.vertical, 4)
                        Divider().background(Color.gray.opacity(0.3))
                    }
                }
                .padding()
                .background(Color.darkSurface)
                .cornerRadius(16)
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Buyers Section
    private var buyersSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Top Buyers", subtitle: "Ranked by volume")
                .padding(.horizontal)

            ForEach(viewModel.buyers) { buyer in
                RankingRow(
                    rank: buyer.rank,
                    name: buyer.buyerName,
                    value: buyer.volumeMLbs.formattedVolume,
                    subtitle: buyer.destinationCountries.prefix(3).joined(separator: ", "),
                    share: buyer.marketSharePct
                )
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Handlers Section
    private var handlersSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Top Handlers", subtitle: "Ranked by market share")
                .padding(.horizontal)

            // Pie chart
            if !viewModel.handlers.isEmpty {
                Chart(viewModel.handlers.prefix(8)) { handler in
                    SectorMark(
                        angle: .value("Share", handler.marketSharePct),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .foregroundStyle(by: .value("Handler", handler.handlerName))
                    .cornerRadius(4)
                }
                .chartLegend(position: .bottom, spacing: 8)
                .frame(height: 250)
                .padding()
                .background(Color.darkSurface)
                .cornerRadius(16)
                .padding(.horizontal)
            }

            ForEach(viewModel.handlers) { handler in
                RankingRow(
                    rank: handler.rank,
                    name: handler.handlerName,
                    value: handler.volumeMLbs.formattedVolume,
                    subtitle: "\(handler.marketSharePct.formattedSharePercent) share",
                    share: handler.marketSharePct
                )
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Varieties Section
    private var varietiesSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Variety Performance", subtitle: "Volume and pricing by variety")
                .padding(.horizontal)

            if !viewModel.varieties.isEmpty {
                Chart(viewModel.varieties.prefix(10)) { v in
                    BarMark(
                        x: .value("Variety", v.variety),
                        y: .value("Volume", v.volumeMLbs)
                    )
                    .foregroundStyle(Color.tealPrimary.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .padding()
                .background(Color.darkSurface)
                .cornerRadius(16)
                .padding(.horizontal)
            }

            ForEach(viewModel.varieties) { v in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(v.variety)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        Text("\(v.transactionCount) transactions")
                            .font(.caption2)
                            .foregroundColor(.textSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(v.volumeMLbs.formattedVolume)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        if let price = v.avgPrice {
                            Text(price.formattedPrice)
                                .font(.caption)
                                .foregroundColor(.amberAccent)
                        }
                    }
                }
                .padding()
                .background(Color.darkSurface)
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }
}
