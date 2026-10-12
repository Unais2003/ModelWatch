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
        ViewThatFits(in: .horizontal) {
            HStack {
                headerTitle
                Spacer()
                rangePicker
            }

            VStack(alignment: .leading, spacing: 12) {
                headerTitle
                rangePicker
            }
        }
    }

    private var headerTitle: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Usage Overview")
                .font(.title)
                .fontWeight(.semibold)
            Text(analyticsSubtitle)
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }

    private var rangePicker: some View {
        Picker("Range", selection: Bindable(viewModel).selectedRange) {
            ForEach(AnalyticsRange.allCases) { range in
                Text(range.title).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 280)
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
            if let total = viewModel.subscriptionTotals.first,
               viewModel.subscriptionTotals.count == 1 {
                "\(total.monthlyCost.formatted(.currency(code: total.currencyCode)))/mo"
            } else if viewModel.subscriptionTotals.isEmpty {
                "0/mo"
            } else {
                "\(viewModel.subscriptionTotals.count) currencies"
            }
        case .empty:
            "0/mo"
        case .idle, .loading, .failed:
            "—"
        }
    }

    private var summaryCards: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 180), spacing: 16)],
            spacing: 16
        ) {
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
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Usage by application")
                .accessibilityValue(usageAccessibilityValue)
            }
        }
        .padding(16)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var usageAccessibilityValue: String {
        viewModel.usageByApp.map { item in
            let duration = DurationFormatter.short.string(from: item.duration) ?? "0 minutes"
            return "\(item.applicationName), \(duration)"
        }
        .joined(separator: "; ")
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

private struct SettingsContent: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Settings", systemImage: "gearshape")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Configure ModelWatch preferences.")
                .foregroundStyle(.secondary)

            Button("Open Settings…") {
                openSettings()
            }
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }
}

struct DashboardLoadingView: View {
    let title: String

    var body: some View {
        ProgressView(title)
            .frame(maxWidth: .infinity, minHeight: 180)
    }
}

struct DashboardStatusView: View {
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
                .accessibilityHidden(true)
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
