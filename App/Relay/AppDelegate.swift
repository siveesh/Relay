import AppKit
import Carbon.HIToolbox

/// Owns the AppKit-level lifecycle that SwiftUI scenes cannot reach: the activation policy,
/// the global hot key, and the floating palette panel.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    /// Persisted preference key for the dock-icon toggle (shared with `SettingsView`).
    static let showDockIconKey = "relay.showDockIcon"

    let environment = AppEnvironment.live()

    private var paletteController: PalettePanelController?
    private var resultPresenter: ResultPanelController?
    private var hotKey: GlobalHotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        applyActivationPolicy()

        // Load persisted state (seeds samples on first run) and request notification access.
        Task {
            await environment.library.load()
            await environment.taskLibrary.load()
            await environment.history.load()
            await environment.notifications.requestAuthorization()
        }

        // Wire execution results to a transient glass panel.
        let presenter = ResultPanelController()
        resultPresenter = presenter
        environment.runCoordinator.onResult = { [weak presenter] record in
            presenter?.show(record)
        }

        let controller = PalettePanelController(environment: environment)
        paletteController = controller

        // Default global shortcut: ⌥Space. Made configurable in a later milestone.
        hotKey = GlobalHotKey(keyCode: UInt32(kVK_Space), modifiers: UInt32(optionKey)) { [weak controller] in
            controller?.toggle()
        }
    }

    /// Exposed so the menu bar can summon the palette.
    func togglePalette() {
        paletteController?.toggle()
    }

    private func applyActivationPolicy() {
        let showDock = UserDefaults.standard.bool(forKey: Self.showDockIconKey)
        NSApp.setActivationPolicy(showDock ? .regular : .accessory)
    }
}
