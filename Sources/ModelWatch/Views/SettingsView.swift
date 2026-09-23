import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    let viewModel: SettingsViewModel
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showMenuBarStatus") private var showMenuBarStatus = true
    @State private var isChoosingApplication = false
    @State private var importerError: String?

    var body: some View {
        TabView {
            Form {
                Section("Activity Monitoring") {
                    Toggle(
                        "Enable activity monitoring",
                        isOn: Binding(
                            get: { viewModel.isMonitoringEnabled },
                            set: { viewModel.setMonitoringEnabled($0) }
                        )
                    )
                    .disabled(
                        viewModel.trackedApplications.isEmpty && !viewModel.isMonitoringEnabled
                    )

                    Text(viewModel.monitoringStatus)
                        .font(.caption)
                        .foregroundStyle(viewModel.hasMonitoringError ? Color.red : Color.secondary)
                }

                Section("Approved Applications") {
                    if viewModel.trackedApplications.isEmpty {
                        Text("No applications selected. ModelWatch will not record activity.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.trackedApplications) { application in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(application.displayName)
                                    Text(application.bundleIdentifier)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Button("Remove", role: .destructive) {
                                    viewModel.removeApplication(application)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }

                    Button("Add Application…") {
                        isChoosingApplication = true
                    }

                    if let errorMessage = viewModel.applicationSelectionError ?? importerError {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Text("ModelWatch stores only the approved application's name, bundle identifier, and session times. It does not read windows, keystrokes, or screen content.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .formStyle(.grouped)
            .tabItem {
                Label("Monitoring", systemImage: "eye")
            }

            Form {
                Toggle("Launch at login", isOn: $launchAtLogin)
                Toggle("Show menu bar status", isOn: $showMenuBarStatus)
            }
            .formStyle(.grouped)
            .tabItem {
                Label("General", systemImage: "gearshape")
            }

            Form {
                LabeledContent("Application", value: viewModel.appName)
                LabeledContent("Minimum macOS", value: viewModel.minimumSystemVersion)
            }
            .formStyle(.grouped)
            .tabItem {
                Label("About", systemImage: "info.circle")
            }
        }
        .frame(width: 520, height: 460)
        .scenePadding()
        .fileImporter(
            isPresented: $isChoosingApplication,
            allowedContentTypes: [.applicationBundle],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case let .success(urls):
                guard let url = urls.first else { return }
                importerError = nil
                Task {
                    await viewModel.addApplication(at: url)
                }
            case let .failure(error):
                importerError = error.localizedDescription
            }
        }
    }
}
