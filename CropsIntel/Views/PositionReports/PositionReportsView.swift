import SwiftUI

struct PositionReportsView: View {
    @StateObject private var viewModel = PositionReportsViewModel()
    @State private var selectedReport: PositionReport?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                if viewModel.isLoading && viewModel.reports.isEmpty {
                    LoadingView()
                } else {
                    VStack(spacing: 0) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Position Reports")
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    Text("\(viewModel.reports.count) reports available")
                                        .font(.subheadline)
                                        .foregroundColor(.textSecondary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal)

                            // Search Bar
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.textSecondary)
                                TextField("Search reports...", text: $viewModel.searchText)
                                    .foregroundColor(.white)
                                    .autocapitalization(.none)
                                if !viewModel.searchText.isEmpty {
                                    Button(action: { viewModel.searchText = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.textSecondary)
                                    }
                                }
                            }
                            .padding(12)
                            .background(Color.darkSurface)
                            .cornerRadius(12)
                            .padding(.horizontal)

                            // Crop Year Filter
                            if !viewModel.availableCropYears.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        FilterChipView(
                                            label: "All Years",
                                            isSelected: viewModel.selectedCropYear == nil,
                                            action: { viewModel.selectedCropYear = nil }
                                        )
                                        ForEach(viewModel.availableCropYears, id: \.self) { year in
                                            FilterChipView(
                                                label: "CY \(year)",
                                                isSelected: viewModel.selectedCropYear == year,
                                                action: { viewModel.selectedCropYear = year }
                                            )
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.top)

                        if let error = viewModel.errorMessage {
                            ErrorBanner(message: error) {
                                viewModel.loadReports()
                            }
                            .padding()
                        }

                        // Reports List
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(viewModel.filteredReports) { report in
                                    PositionReportCard(report: report)
                                        .onTapGesture {
                                            selectedReport = report
                                        }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 12)
                            .padding(.bottom, 80)
                        }
                        .refreshable {
                            viewModel.loadReports()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedReport) { report in
                PositionReportDetailView(report: report)
            }
            .onAppear {
                if viewModel.reports.isEmpty {
                    viewModel.loadReports()
                }
            }
        }
    }
}

// MARK: - Filter Chip
struct FilterChipView: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.amberAccent : Color.darkSurface)
                .cornerRadius(20)
        }
    }
}

// MARK: - Report Card
struct PositionReportCard: View {
    let report: PositionReport

    var body: some View {
        HStack(spacing: 14) {
            // Month indicator
            VStack(spacing: 2) {
                Text(monthAbbrev)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.amberAccent)
                Text(yearString)
                    .font(.system(size: 10))
                    .foregroundColor(.textSecondary)
            }
            .frame(width: 44, height: 44)
            .background(Color.amberAccent.opacity(0.15))
            .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(report.displayMonth)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text("Crop Year \(report.cropYear ?? 0)")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            // Key metric
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.1fM", report.marketableSupplyMLbs))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.amberAccent)
                Text("Mkt Supply")
                    .font(.system(size: 10))
                    .foregroundColor(.textSecondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .padding(14)
        .background(Color.darkSurface)
        .cornerRadius(14)
    }

    private var monthAbbrev: String {
        let display = report.displayMonth
        return String(display.prefix(3)).uppercased()
    }

    private var yearString: String {
        let display = report.displayMonth
        if display.contains("-") {
            return String(display.suffix(4))
        }
        return "\(report.cropYear ?? 0)"
    }
}

// MARK: - Report Detail Sheet
struct PositionReportDetailView: View {
    let report: PositionReport
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Text(report.displayMonth)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("Crop Year \(report.cropYear ?? 0)")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.top, 20)

                        // Key Metrics Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                        ], spacing: 12) {
                            MetricCard(
                                title: "Crop Receipts",
                                value: String(format: "%.2fM lbs", report.cropReceiptsMLbs),
                                icon: "arrow.down.doc.fill",
                                color: .tealPrimary
                            )
                            MetricCard(
                                title: "Domestic YTD",
                                value: String(format: "%.2fM lbs", report.domesticYtdMLbs),
                                icon: "house.fill",
                                color: .blue
                            )
                            MetricCard(
                                title: "Export YTD",
                                value: String(format: "%.2fM lbs", report.exportYtdMLbs),
                                icon: "airplane",
                                color: .amberAccent
                            )
                            MetricCard(
                                title: "Marketable Supply",
                                value: String(format: "%.2fM lbs", report.marketableSupplyMLbs),
                                icon: "chart.bar.fill",
                                color: .green
                            )
                        }
                        .padding(.horizontal)

                        // Additional Details
                        VStack(spacing: 0) {
                            DetailRow(label: "New Contracts", value: String(format: "%.2fM lbs", report.newContractsMLbs))
                            Divider().background(Color.darkBackground)
                            DetailRow(label: "Total Commitments", value: String(format: "%.2fM lbs", report.totalCommitmentsMLbs))
                            Divider().background(Color.darkBackground)
                            DetailRow(label: "Uncommitted", value: String(format: "%.2fM lbs", report.uncommittedMLbs))
                            Divider().background(Color.darkBackground)
                            DetailRow(label: "Total Supply", value: String(format: "%.2fM lbs", report.totalSupplyMLbs))
                        }
                        .background(Color.darkSurface)
                        .cornerRadius(14)
                        .padding(.horizontal)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.amberAccent)
                }
            }
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            Text(title)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .padding(14)
        .background(Color.darkSurface)
        .cornerRadius(14)
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
