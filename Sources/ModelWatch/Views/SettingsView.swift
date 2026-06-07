import SwiftUI

struct SettingsView: View {
    let viewModel: SettingsViewModel
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showMenuBarStatus") private var showMenuBarStatus = true

    var body: some View {
        TabView {
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
        .frame(width: 460, height: 260)
        .scenePadding()
    }
}
