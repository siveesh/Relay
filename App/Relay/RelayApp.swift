import SwiftUI

/// The app entry point. A menu bar (`LSUIElement`) app: the primary surface is the global
/// hot key palette; the menu bar provides browsing and settings.
@main
struct RelayApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent(
                environment: appDelegate.environment,
                onOpenPalette: { appDelegate.togglePalette() }
            )
        } label: {
            Image(systemName: "chevron.right.circle.fill")
        }
        .menuBarExtraStyle(.menu)

        Window("Command Library", id: WindowID.library) {
            CommandLibraryView(library: appDelegate.environment.library)
        }
        .defaultSize(width: 880, height: 620)

        Window("Execution History", id: WindowID.history) {
            HistoryView(history: appDelegate.environment.history)
        }
        .defaultSize(width: 820, height: 560)

        Settings {
            SettingsView()
        }
    }
}

/// Stable identifiers for the app's auxiliary windows.
enum WindowID {
    static let library = "relay.library"
    static let history = "relay.history"
}
