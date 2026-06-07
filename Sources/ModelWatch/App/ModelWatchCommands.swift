import AppKit
import SwiftUI

struct ModelWatchCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About ModelWatch") {
                NSApplication.shared.orderFrontStandardAboutPanel(nil)
            }
        }

        CommandMenu(AppConstants.appName) {
            Button("Open Dashboard") {
                openWindow(id: AppWindowID.dashboard.rawValue)
            }
            .keyboardShortcut("0", modifiers: [.command])
        }
    }
}
