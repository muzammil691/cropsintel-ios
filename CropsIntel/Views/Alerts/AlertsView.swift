import SwiftUI

struct AlertsView: View {
    @StateObject private var viewModel = AlertsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                if viewModel.isLoading && viewModel.alerts.isEmpty {
                    LoadingView()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            HStack {
                                Text("Alerts")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Spacer()
                                Button(action: { viewModel.showCreateSheet = true }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.tealPrimary)
                                }
                            }
                            .padding(.horizontal)

                            if let error = viewModel.errorMessage {
                                ErrorBanner(message: error) {
                                    viewModel.loadAlerts()
                                }
                                .padding(.horizontal)
                            }

                            if viewModel.alerts.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "bell.slash")
                                        .font(.system(size: 48))
                                        .foregroundColor(.textSecondary)
                                    Text("No Alerts")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    Text("Create price or volume alerts to get notified when market conditions change.")
                                        .font(.subheadline)
                                        .foregroundColor(.textSecondary)
                                        .multilineTextAlignment(.center)
                                    Button(action: { viewModel.showCreateSheet = true }) {
                                        Text("Create Alert")
                                            .fontWeight(.semibold)
                                            .padding(.horizontal, 24)
                                            .padding(.vertical, 12)
                                            .background(Color.tealPrimary)
                                            .foregroundColor(.white)
                                            .cornerRadius(12)
                                    }
                                }
                                .padding(.top, 60)
                                .padding(.horizontal, 40)
                            } else {
                                ForEach(viewModel.alerts) { alert in
                                    AlertCard(alert: alert) {
                                        viewModel.deleteAlert(alert)
                                    }
                                    .padding(.horizontal)
                                }
                            }

                            Spacer(minLength: 80)
                        }
                        .padding(.top)
                    }
                    .refreshable {
                        viewModel.loadAlerts()
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.loadAlerts()
            }
            .sheet(isPresented: $viewModel.showCreateSheet) {
                CreateAlertSheet(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Alert Card
struct AlertCard: View {
    let alert: UserAlert
    let onDelete: () -> Void

    var alertTypeInfo: (icon: String, color: Color, label: String) {
        switch alert.alertType {
        case "price_above":
            return ("arrow.up.circle.fill", .green, "Price Above")
        case "price_below":
            return ("arrow.down.circle.fill", .red, "Price Below")
        case "volume_above":
            return ("chart.bar.fill", .blue, "Volume Above")
        case "volume_below":
            return ("chart.bar.fill", .orange, "Volume Below")
        default:
            return ("bell.fill", .gray, alert.alertType)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: alertTypeInfo.icon)
                .font(.title2)
                .foregroundColor(alertTypeInfo.color)

            VStack(alignment: .leading, spacing: 4) {
                Text(alertTypeInfo.label)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text(alert.condition)
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                HStack(spacing: 8) {
                    Text("Threshold: \(String(format: "%.2f", alert.threshold))")
                        .font(.caption2)
                        .foregroundColor(.amberAccent)

                    if let variety = alert.variety {
                        Text(variety)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.tealPrimary.opacity(0.2))
                            .foregroundColor(.tealPrimary)
                            .cornerRadius(4)
                    }
                }
            }

            Spacer()

            VStack(spacing: 8) {
                Circle()
                    .fill(alert.isActive ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.7))
                }
            }
        }
        .padding()
        .background(Color.darkSurface)
        .cornerRadius(16)
    }
}

// MARK: - Create Alert Sheet
struct CreateAlertSheet: View {
    @ObservedObject var viewModel: AlertsViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Alert Type
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Alert Type")
                                .font(.caption)
                                .foregroundColor(.textSecondary)

                            Picker("Type", selection: $viewModel.alertType) {
                                ForEach(viewModel.alertTypes, id: \.0) { type in
                                    Text(type.1).tag(type.0)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        // Condition
                        FormField(title: "Condition", text: $viewModel.condition, placeholder: "e.g., Nonpareil price exceeds $3.50")

                        // Threshold
                        FormField(title: "Threshold Value", text: $viewModel.threshold, placeholder: "e.g., 3.50", keyboard: .decimalPad)

                        // Optional Filters
                        Text("Optional Filters")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        FormField(title: "Variety", text: $viewModel.variety, placeholder: "e.g., Nonpareil")
                        FormField(title: "Handler", text: $viewModel.handler, placeholder: "e.g., Blue Diamond")
                        FormField(title: "Destination", text: $viewModel.destination, placeholder: "e.g., India")

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }

                        Button(action: viewModel.createAlert) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Create Alert")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.tealPrimary)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isLoading)
                    }
                    .padding()
                }
            }
            .navigationTitle("New Alert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.tealPrimary)
                }
            }
        }
    }
}

struct FormField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.textSecondary)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .padding()
                .background(Color.darkSurface)
                .cornerRadius(12)
                .foregroundColor(.white)
                .keyboardType(keyboard)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.tealPrimary.opacity(0.3), lineWidth: 1)
                )
        }
    }
}
