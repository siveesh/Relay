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

        Settings {
            SettingsView()
        }
    }
}
