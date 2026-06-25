import AppKit
import SwiftUI
import RelayCore
import RelayUI

/// Shows a transient Liquid Glass panel with the result of the most recent execution.
@MainActor
final class ResultPanelController: NSObject, NSWindowDelegate {

    private var panel: FloatingPanel?

    func show(_ record: ExecutionRecord) {
        let panel = panel ?? makePanel()
        self.panel = panel

        let view = ExecutionResultView(record: record) { [weak self] in self?.hide() }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(16)
        panel.contentView = NSHostingView(rootView: view)

        position(panel)
        NSApp.activate()
        panel.makeKeyAndOrderFront(nil)
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func makePanel() -> FloatingPanel {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.delegate = self
        return panel
    }

    private func position(_ panel: NSPanel) {
        panel.layoutIfNeeded()
        let size = panel.contentView?.fittingSize ?? NSSize(width: 600, height: 400)
        panel.setContentSize(size)
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        panel.setFrameOrigin(NSPoint(
            x: visible.midX - size.width / 2,
            y: visible.midY - size.height / 2
        ))
    }
}
