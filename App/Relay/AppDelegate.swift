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
    private var hotKey: GlobalHotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        applyActivationPolicy()

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
