import SwiftUI

// MARK: - KPI Card
struct KPICard: View {
    let title: String
    let value: String
    let change: String?
    let icon: String
    let color: Color

    init(title: String, value: String, change: String? = nil, icon: String, color: Color = .tealPrimary) {
        self.title = title
        self.value = value
        self.change = change
        self.icon = icon
        self.color = color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Spacer()
                if let change = change {
                    Text(change)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(change.hasPrefix("+") ? .green : .red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            (change.hasPrefix("+") ? Color.green : Color.red)
                                .opacity(0.15)
                        )
                        .cornerRadius(4)
                }
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .padding()
        .background(Color.darkSurface)
        .cornerRadius(16)
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let subtitle: String?

    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.tealPrimary)
            Text("Loading...")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Error View
struct ErrorBanner: View {
    let message: String
    let retryAction: (() -> Void)?

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.amberAccent)
            Text(message)
                .font(.caption)
                .foregroundColor(.white)
            Spacer()
            if let retry = retryAction {
                Button("Retry", action: retry)
                    .font(.caption)
                    .foregroundColor(.tealPrimary)
            }
        }
        .padding()
        .background(Color.red.opacity(0.15))
        .cornerRadius(12)
    }
}

// MARK: - Ranking Row
struct RankingRow: View {
    let rank: Int
    let name: String
    let value: String
    let subtitle: String
    let share: Double

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.tealPrimary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                // Share bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.darkCard)
                            .frame(width: 60, height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.tealPrimary)
                            .frame(width: min(60, 60 * share / 100), height: 4)
                    }
                }
                .frame(width: 60, height: 4)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color.darkSurface)
        .cornerRadius(12)
    }
}

// MARK: - Crop Year Picker
struct CropYearPicker: View {
    @Binding var selectedYear: Int
    let years: [Int]

    var body: some View {
        Menu {
            ForEach(years, id: \.self) { year in
                Button(action: { selectedYear = year }) {
                    HStack {
                        Text("CY \(year)/\(year + 1 - 2000)")
                        if year == selectedYear {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text("CY \(selectedYear)/\(selectedYear + 1 - 2000)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .foregroundColor(.tealPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.tealPrimary.opacity(0.15))
            .cornerRadius(8)
        }
    }
}
