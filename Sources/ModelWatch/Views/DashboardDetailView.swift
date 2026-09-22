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
                analyticsContent
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
                Text(analyticsSubtitle)
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

    private var analyticsSubtitle: String {
        switch viewModel.analyticsState {
        case .idle, .loading:
            "Loading usage…"
        case .loaded:
            formattedTotalTime
        case .empty:
            "No activity recorded"
        case .failed:
            "Usage unavailable"
        }
    }

    private var totalTimeValue: String {
        switch viewModel.analyticsState {
        case .loaded:
            formattedTotalTime
        case .empty:
            "0 min"
        case .idle, .loading, .failed:
            "—"
        }
    }

    private var appCountValue: String {
        switch viewModel.analyticsState {
        case .loaded:
            "\(viewModel.usageSummary.trackedApplicationCount)"
        case .empty:
            "0"
        case .idle, .loading, .failed:
            "—"
        }
    }

    private var subscriptionCostValue: String {
        switch viewModel.subscriptionsState {
        case .loaded:
            "$\(String(format: "%.0f", viewModel.totalMonthlyCost))/mo"
        case .empty:
            "$0/mo"
        case .idle, .loading, .failed:
            "—"
        }
    }

    private var summaryCards: some View {
        HStack(spacing: 16) {
            SummaryCard(title: "Total Time", value: totalTimeValue, icon: "clock")
            SummaryCard(title: "Apps Used", value: appCountValue, icon: "app.badge")
            SummaryCard(title: "Subscriptions", value: subscriptionCostValue, icon: "creditcard")
        }
    }

    @ViewBuilder
    private var analyticsContent: some View {
        switch viewModel.analyticsState {
        case .idle, .loading:
            DashboardLoadingView(title: "Loading usage…")
        case .loaded:
            usageChart
            appBreakdown
        case .empty:
            DashboardStatusView(
                title: "No Usage Yet",
                message: "Tracked application activity will appear here.",
                systemImage: "chart.bar"
            )
        case let .failed(message):
            DashboardStatusView(
                title: "Usage Unavailable",
                message: message,
                systemImage: "exclamationmark.triangle",
                actionTitle: "Try Again"
            ) {
                Task { await viewModel.reloadAnalytics() }
            }
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
                header
                subscriptionsContent
            }
            .padding(24)
        }
        .navigationTitle("Subscriptions")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Subscriptions")
                .font(.title)
                .fontWeight(.semibold)
            Text(subscriptionSubtitle)
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }

    private var subscriptionSubtitle: String {
        switch viewModel.subscriptionsState {
        case .idle, .loading:
            "Loading subscriptions…"
        case .loaded:
            "$\(String(format: "%.2f", viewModel.totalMonthlyCost)) / month total"
        case .empty:
            "No active subscriptions"
        case .failed:
            "Subscriptions unavailable"
        }
    }

    @ViewBuilder
    private var subscriptionsContent: some View {
        switch viewModel.subscriptionsState {
        case .idle, .loading:
            DashboardLoadingView(title: "Loading subscriptions…")
        case .loaded:
            subscriptionList
        case .empty:
            DashboardStatusView(
                title: "No Subscriptions",
                message: "Subscriptions you add will appear here.",
                systemImage: "creditcard"
            )
        case let .failed(message):
            DashboardStatusView(
                title: "Subscriptions Unavailable",
                message: message,
                systemImage: "exclamationmark.triangle",
                actionTitle: "Try Again"
            ) {
                Task { await viewModel.reloadSubscriptions() }
            }
        }
    }

    private var subscriptionList: some View {
        ForEach(viewModel.subscriptions, id: \.id) { subscription in
            VStack(spacing: 0) {
                HStack {
                    Label(subscription.serviceName, systemImage: "creditcard.fill")
                        .font(.headline)
                    Spacer()
                    Text("$\(String(format: "%.2f", subscription.monthlyCost))/mo")
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)

                if let renewalDate = subscription.renewalDate {
                    HStack {
                        Text("Next renewal")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(renewalDate, style: .date)
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

private struct DashboardLoadingView: View {
    let title: String

    var body: some View {
        ProgressView(title)
            .frame(maxWidth: .infinity, minHeight: 180)
    }
}

private struct DashboardStatusView: View {
    let title: String
    let message: String
    let systemImage: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 180)
        .padding(20)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
