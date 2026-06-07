import AppKit
import SwiftUI

struct MenuBarView: View {
    let viewModel: MenuBarViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Text(viewModel.statusTitle)
            .foregroundStyle(.secondary)

        Divider()

        Button("Open Dashboard") {
            openWindow(id: AppWindowID.dashboard.rawValue)
        }

        SettingsLink {
            Text("Settings...")
        }

        Divider()

        Button("Quit ModelWatch") {
            NSApplication.shared.terminate(nil)
        }
    }
}
