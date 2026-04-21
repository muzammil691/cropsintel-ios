import SwiftUI
import Charts

struct QualityView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = QualityViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                if viewModel.isLoading && viewModel.grades.isEmpty {
                    LoadingView()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            HStack {
                                Text("Quality")
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

                            // Compliance Overview
                            if let compliance = viewModel.compliance {
                                VStack(alignment: .leading, spacing: 16) {
                                    SectionHeader(title: "Compliance Overview")

                                    HStack(spacing: 16) {
                                        ComplianceGauge(
                                            value: compliance.overall.complianceRatePct,
                                            title: "Overall"
                                        )

                                        VStack(alignment: .leading, spacing: 8) {
                                            ComplianceStat(
                                                label: "Total Records",
                                                value: compliance.overall.totalRecords.formattedCount
                                            )
                                            ComplianceStat(
                                                label: "Graded",
                                                value: compliance.overall.gradedRecords.formattedCount
                                            )
                                            ComplianceStat(
                                                label: "Ungraded",
                                                value: compliance.overall.ungradedRecords.formattedCount
                                            )
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.darkSurface)
                                .cornerRadius(16)
                                .padding(.horizontal)
                            }

                            // Grade Distribution
                            if !viewModel.grades.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    SectionHeader(title: "Grade Distribution", subtitle: "Volume by quality grade")

                                    Chart(viewModel.grades) { grade in
                                        SectorMark(
                                            angle: .value("Volume", grade.volumeMLbs),
                                            innerRadius: .ratio(0.5),
                                            angularInset: 1.5
                                        )
                                        .foregroundStyle(by: .value("Grade", grade.grade))
                                        .cornerRadius(4)
                                    }
                                    .chartLegend(position: .bottom, spacing: 8)
                                    .frame(height: 250)
                                }
                                .padding()
                                .background(Color.darkSurface)
                                .cornerRadius(16)
                                .padding(.horizontal)

                                // Grade Details
                                VStack(alignment: .leading, spacing: 8) {
                                    SectionHeader(title: "Grade Details")

                                    ForEach(viewModel.grades) { grade in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(grade.grade)
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.white)
                                                Text("\(grade.transactionCount) transactions")
                                                    .font(.caption2)
                                                    .foregroundColor(.textSecondary)
                                            }
                                            Spacer()
                                            VStack(alignment: .trailing, spacing: 2) {
                                                Text(grade.volumeMLbs.formattedVolume)
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.white)
                                                HStack(spacing: 4) {
                                                    Text(grade.sharePct.formattedSharePercent)
                                                        .font(.caption2)
                                                        .foregroundColor(.tealPrimary)
                                                    if let price = grade.avgPrice {
                                                        Text("| \(price.formattedPrice)")
                                                            .font(.caption2)
                                                            .foregroundColor(.amberAccent)
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.vertical, 6)
                                        Divider().background(Color.gray.opacity(0.3))
                                    }
                                }
                                .padding()
                                .background(Color.darkSurface)
                                .cornerRadius(16)
                                .padding(.horizontal)
                            }

                            // Handler Compliance
                            if let compliance = viewModel.compliance, !compliance.byHandler.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    SectionHeader(title: "Compliance by Handler")

                                    ForEach(compliance.byHandler.prefix(10)) { handler in
                                        HStack {
                                            Text(handler.handlerName)
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                            Spacer()
                                            Text(handler.complianceRatePct.formattedSharePercent)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(
                                                    handler.complianceRatePct >= 90 ? .green :
                                                    handler.complianceRatePct >= 70 ? .amberAccent : .red
                                                )
                                        }
                                        .padding(.vertical, 4)
                                    }
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
                        viewModel.loadData(cropYear: appState.currentCropYear)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                if viewModel.grades.isEmpty {
                    viewModel.loadData(cropYear: appState.currentCropYear)
                }
            }
            .onChange(of: appState.currentCropYear) { newYear in
                viewModel.loadData(cropYear: newYear)
            }
        }
    }
}

// MARK: - Helper Views
struct ComplianceGauge: View {
    let value: Double
    let title: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.darkCard, lineWidth: 8)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: value / 100)
                    .stroke(
                        value >= 90 ? Color.green :
                        value >= 70 ? Color.amberAccent : Color.red,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(value))%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            Text(title)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
    }
}

struct ComplianceStat: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.textSecondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
}
