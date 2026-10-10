import SwiftUI
import UniformTypeIdentifiers

struct DataManagementSettingsView: View {
    let viewModel: SettingsViewModel

    @State private var pendingDeletion: DataDeletionScope?
    @State private var exportDocument: ModelWatchExportDocument?
    @State private var isExporting = false

    var body: some View {
        Form {
            Section("Stored Locally") {
                dataSummaryContent
            }

            Section("Export") {
                Button("Export JSON…", systemImage: "square.and.arrow.up") {
                    prepareExport()
                }
                .disabled(viewModel.isPerformingDataOperation)

                Text("The export contains activity session times and subscription records. It does not contain prompts, window titles, or account credentials.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Delete Data") {
                Button("Delete Activity History…", role: .destructive) {
                    pendingDeletion = .activity
                }
                .disabled(
                    viewModel.isPerformingDataOperation
                        || viewModel.localDataSummary.activitySessionCount == 0
                )

                Button("Delete Subscription Data…", role: .destructive) {
                    pendingDeletion = .subscriptions
                }
                .disabled(
                    viewModel.isPerformingDataOperation
                        || viewModel.localDataSummary.subscriptionCount == 0
                )

                Button("Delete All Local Data…", role: .destructive) {
                    pendingDeletion = .all
                }
                .disabled(
                    viewModel.isPerformingDataOperation || viewModel.localDataSummary.isEmpty
                )

                Text("Approved application choices and general preferences are retained. If monitoring is active, a new session starts immediately after activity history is cleared.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let message = viewModel.dataOperationMessage {
                Label(message, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }

            if let error = viewModel.dataOperationError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }
        }
        .formStyle(.grouped)
        .task {
            await viewModel.loadLocalDataSummary()
        }
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .json,
            defaultFilename: defaultExportFilename
        ) { result in
            viewModel.reportExportResult(result)
            exportDocument = nil
        }
        .alert(item: $pendingDeletion) { scope in
            Alert(
                title: Text(scope.title),
                message: Text(scope.message),
                primaryButton: .destructive(Text("Delete")) {
                    delete(scope)
                },
                secondaryButton: .cancel()
            )
        }
    }

    @ViewBuilder
    private var dataSummaryContent: some View {
        switch viewModel.localDataState {
        case .idle, .loading:
            ProgressView("Inspecting local data…")
        case .loaded, .empty:
            LabeledContent(
                "Activity sessions",
                value: viewModel.localDataSummary.activitySessionCount.formatted()
            )
            LabeledContent(
                "Subscriptions",
                value: viewModel.localDataSummary.subscriptionCount.formatted()
            )
        case let .failed(message):
            Text(message)
                .foregroundStyle(.red)
            Button("Try Again") {
                Task { await viewModel.loadLocalDataSummary() }
            }
        }
    }

    private var defaultExportFilename: String {
        let date = Date().formatted(.iso8601.year().month().day().dateSeparator(.dash))
        return "ModelWatch-Export-\(date)"
    }

    private func prepareExport() {
        viewModel.clearDataOperationFeedback()
        Task {
            guard let document = await viewModel.prepareExport() else { return }
            exportDocument = document
            isExporting = true
        }
    }

    private func delete(_ scope: DataDeletionScope) {
        Task {
            switch scope {
            case .activity:
                _ = await viewModel.deleteActivityHistory()
            case .subscriptions:
                _ = await viewModel.deleteSubscriptions()
            case .all:
                _ = await viewModel.deleteAllData()
            }
        }
    }
}

private enum DataDeletionScope: String, Identifiable {
    case activity
    case subscriptions
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .activity:
            "Delete Activity History?"
        case .subscriptions:
            "Delete Subscription Data?"
        case .all:
            "Delete All Local Data?"
        }
    }

    var message: String {
        switch self {
        case .activity:
            "This permanently deletes recorded application sessions."
        case .subscriptions:
            "This permanently deletes every subscription record."
        case .all:
            "This permanently deletes all activity sessions and subscription records."
        }
    }
}
