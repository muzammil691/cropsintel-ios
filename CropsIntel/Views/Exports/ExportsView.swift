import SwiftUI
import Charts

struct ExportsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ExportsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                if viewModel.isLoading && viewModel.destinations.isEmpty {
                    LoadingView()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            HStack {
                                Text("Exports")
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

                            // Top Destinations Chart
                            if !viewModel.destinations.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    SectionHeader(title: "Top Destinations", subtitle: "Export volume by country")

                                    Chart(viewModel.destinations.prefix(10)) { dest in
                                        BarMark(
                                            x: .value("Volume", dest.volumeMLbs),
                                            y: .value("Country", dest.country)
                                        )
                                        .foregroundStyle(Color.tealPrimary.gradient)
                                        .cornerRadius(4)
                                    }
                                    .chartXAxis {
                                        AxisMarks { _ in
                                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                                                .foregroundStyle(Color.gray.opacity(0.3))
                                            AxisValueLabel().foregroundStyle(Color.textSecondary)
                                        }
                                    }
                                    .chartYAxis {
                                        AxisMarks { _ in
                                            AxisValueLabel().foregroundStyle(Color.textSecondary)
                                        }
                                    }
                                    .frame(height: 300)
                                }
                                .padding()
                                .background(Color.darkSurface)
                                .cornerRadius(16)
                                .padding(.horizontal)
                            }

                            // Shipment Velocity
                            if !viewModel.velocity.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    SectionHeader(
                                        title: "Shipment Velocity",
                                        subtitle: viewModel.selectedCountry != nil
                                            ? "Weekly volume - \(viewModel.selectedCountry!)"
                                            : "Weekly shipment volume (M lbs)"
                                    )

                                    Chart(viewModel.velocity) { point in
                                        AreaMark(
                                            x: .value("Week", point.weekStart),
                                            y: .value("Volume", point.volumeMLbs)
                                        )
                                        .foregroundStyle(Color.tealPrimary.opacity(0.2))

                                        LineMark(
                                            x: .value("Week", point.weekStart),
                                            y: .value("4W MA", point.movingAvg4w)
                                        )
                                        .foregroundStyle(Color.amberAccent)
                                        .lineStyle(StrokeStyle(lineWidth: 2))
                                    }
                                    .frame(height: 200)
                                }
                                .padding()
                                .background(Color.darkSurface)
                                .cornerRadius(16)
                                .padding(.horizontal)
                            }

                            // Destination List
                            SectionHeader(title: "All Destinations")
                                .padding(.horizontal)

                            ForEach(viewModel.destinations) { dest in
                                Button(action: {
                                    viewModel.loadVelocityForCountry(dest.country, cropYear: appState.currentCropYear)
                                }) {
                                    HStack {
                                        Text("\(dest.rank)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.tealPrimary)
                                            .frame(width: 24)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(dest.country)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.white)
                                            Text("\(dest.transactionCount) shipments")
                                                .font(.caption2)
                                                .foregroundColor(.textSecondary)
                                        }

                                        Spacer()

                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(dest.volumeMLbs.formattedVolume)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                            Text(dest.marketSharePct.formattedSharePercent)
                                                .font(.caption2)
                                                .foregroundColor(.tealPrimary)
                                        }

                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .foregroundColor(.textSecondary)
                                    }
                                    .padding()
                                    .background(Color.darkSurface)
                                    .cornerRadius(12)
                                }
                                .padding(.horizontal)
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
                if viewModel.destinations.isEmpty {
                    viewModel.loadData(cropYear: appState.currentCropYear)
                }
            }
            .onChange(of: appState.currentCropYear) { newYear in
                viewModel.loadData(cropYear: newYear)
            }
        }
    }
}
