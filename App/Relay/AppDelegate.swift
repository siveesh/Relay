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
    private var hotKeyObserver: NSObjectProtocol?
    private var variablesObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        applyActivationPolicy()

        // Load persisted state (seeds samples on first run) and request notification access.
        Task {
            await environment.library.load()
            await environment.taskLibrary.load()
            await environment.history.load()
            await environment.notifications.requestAuthorization()
        }

        // Wire execution progress + results to a transient glass panel.
        let presenter = ResultPanelController()
        resultPresenter = presenter
        let coordinator = environment.runCoordinator
        coordinator.onRunningStarted = { [weak presenter, weak coordinator] name in
            presenter?.showRunning(name) { coordinator?.cancelCurrent() }
        }
        coordinator.onResult = { [weak presenter] record in
            presenter?.show(record)
        }

        let controller = PalettePanelController(environment: environment)
        paletteController = controller

        registerHotKey(HotKeyPreference.load())

        // Re-register whenever the user changes the shortcut in Settings.
        hotKeyObserver = NotificationCenter.default.addObserver(
            forName: .hotKeyPreferenceDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.registerHotKey(HotKeyPreference.load())
        }

        // Rebuild the variable resolver when the user edits custom variables.
        variablesObserver = NotificationCenter.default.addObserver(
            forName: .customVariablesDidChange,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let dict = note.object as? [String: String] else { return }
            self?.environment.updateCustomVariables(dict)
        }
    }

    /// Exposed so the menu bar can summon the palette.
    func togglePalette() {
        paletteController?.toggle()
    }

    // MARK: Private

    private func registerHotKey(_ pref: HotKeyPreference) {
        hotKey = nil   // unregisters the old Carbon hot key via deinit
        hotKey = GlobalHotKey(keyCode: pref.keyCode, modifiers: pref.modifiers) { [weak self] in
            self?.paletteController?.toggle()
        }
    }

    private func applyActivationPolicy() {
        let showDock = UserDefaults.standard.bool(forKey: Self.showDockIconKey)
        NSApp.setActivationPolicy(showDock ? .regular : .accessory)
    }
}
