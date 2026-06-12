import Charts
import SwiftUI

struct DashboardDetailView: View {
    let destination: AppDestination
    let viewModel: DashboardViewModel

    var body: some View {
        switch destination {
        case .overview:
            OverviewContent(viewModel: viewModel)
        case .subscriptions:
            SubscriptionsContent(viewModel: viewModel)
        case .settings:
            SettingsContent()
        }
    }
}

private struct OverviewContent: View {
    let viewModel: DashboardViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                summaryCards
                usageChart
                appBreakdown
            }
            .padding(24)
        }
        .navigationTitle("Overview")
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Usage Overview")
                    .font(.title)
                    .fontWeight(.semibold)
                Text(formattedTotalTime)
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Picker("Range", selection: Bindable(viewModel).selectedRange) {
                ForEach(AnalyticsRange.allCases) { range in
                    Text(range.title).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 280)
        }
    }

    private var formattedTotalTime: String {
        DurationFormatter.short.string(from: viewModel.usageSummary.totalDuration)
            ?? "0 min"
    }

    private var summaryCards: some View {
        HStack(spacing: 16) {
            SummaryCard(title: "Total Time", value: formattedTotalTime, icon: "clock")
            SummaryCard(title: "Apps Used", value: "\(viewModel.usageSummary.trackedApplicationCount)", icon: "app.badge")
            SummaryCard(title: "Subscriptions", value: "$\(String(format: "%.0f", viewModel.totalMonthlyCost))/mo", icon: "creditcard")
        }
    }

    private var usageChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Usage by Application")
                .font(.headline)

            if viewModel.usageByApp.isEmpty {
                Text("No usage data for this period.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                Chart(viewModel.usageByApp) { item in
                    BarMark(
                        x: .value("Duration", item.duration / 60),
                        y: .value("Application", item.applicationName)
                    )
                    .foregroundStyle(by: .value("Application", item.applicationName))
                }
                .chartXAxisLabel("Minutes")
                .frame(height: CGFloat(max(160, viewModel.usageByApp.count * 40)))
            }
        }
        .padding(16)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var appBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)

            ForEach(viewModel.usageByApp) { item in
                HStack {
                    Label(item.applicationName, systemImage: "app.fill")
                    Spacer()
                    Text(DurationFormatter.short.string(from: item.duration) ?? "0 min")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct SubscriptionsContent: View {
    let viewModel: DashboardViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Subscriptions")
                        .font(.title)
                        .fontWeight(.semibold)
                    Text("$\(String(format: "%.2f", viewModel.totalMonthlyCost)) / month total")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }

                if viewModel.subscriptions.isEmpty {
                    Text("No subscriptions added yet.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 60)
                } else {
                    ForEach(viewModel.subscriptions, id: \.id) { sub in
                        VStack(spacing: 0) {
                            HStack {
                                Label(sub.serviceName, systemImage: "creditcard.fill")
                                    .font(.headline)
                                Spacer()
                                Text("$\(String(format: "%.2f", sub.monthlyCost))/mo")
                                    .fontWeight(.semibold)
                                    .monospacedDigit()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)

                            if let renewal = sub.renewalDate {
                                HStack {
                                    Text("Next renewal")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(renewal, style: .date)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 12)
                            }
                        }
                        .background(.background.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding(24)
        }
        .navigationTitle("Subscriptions")
    }
}

private struct SettingsContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Settings", systemImage: "gearshape")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Configure ModelWatch preferences.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(32)
        .navigationTitle("Settings")
    }
}

private struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
