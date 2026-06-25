import AppKit
import SwiftUI
import RelayCore
import RelayUI

/// A borderless, non-activating panel that can still become key so its text field accepts input.
final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// Owns the floating command-palette window: presentation, positioning, and dismissal.
///
/// The panel is rebuilt with a fresh view model each time it is shown so the query starts
/// empty and the library is current.
@MainActor
final class PalettePanelController: NSObject, NSWindowDelegate {

    private let environment: AppEnvironment
    private var panel: FloatingPanel?

    init(environment: AppEnvironment) {
        self.environment = environment
        super.init()
    }

    /// Shows the palette if hidden, hides it if visible.
    func toggle() {
        if let panel, panel.isVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        let panel = panel ?? makePanel()
        self.panel = panel

        let model = environment.makePaletteModel()
        let root = CommandPaletteView(
            model: model,
            onRun: { [weak self] command in self?.run(command) },
            onDismiss: { [weak self] in self?.hide() }
        )
        panel.contentView = NSHostingView(rootView: root)

        position(panel)
        NSApp.activate()
        panel.makeKeyAndOrderFront(nil)
    }

    func hide() {
        panel?.orderOut(nil)
    }

    // MARK: Execution (Milestone 3)

    private func run(_ command: RelayCommand) {
        hide()
        // Confirmation, elevation, execution, logging, and notifications are implemented in
        // Milestone 3. For now we only acknowledge the selection.
        NSLog("Relay: selected command \"%@\" (execution lands in Milestone 3)", command.name)
    }

    // MARK: Window construction & layout

    private func makePanel() -> FloatingPanel {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: RelayTheme.Metrics.paletteWidth + 48, height: 220),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false            // the Liquid Glass panel draws its own shadow
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.animationBehavior = .utilityWindow
        panel.delegate = self
        return panel
    }

    private func position(_ panel: NSPanel) {
        panel.layoutIfNeeded()
        let fitting = panel.contentView?.fittingSize
            ?? NSSize(width: RelayTheme.Metrics.paletteWidth + 48, height: 220)
        panel.setContentSize(fitting)

        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let origin = NSPoint(
            x: visible.midX - fitting.width / 2,
            y: visible.maxY - fitting.height - visible.height * 0.18
        )
        panel.setFrameOrigin(origin)
    }

    // MARK: NSWindowDelegate

    /// Dismiss when the panel loses focus (click outside or app switch) — Spotlight behaviour.
    func windowDidResignKey(_ notification: Notification) {
        hide()
    }
}
