import AppKit
import SwiftUI
import RelayCore
import RelayUI

/// Shows a transient Liquid Glass panel with the result of the most recent execution.
@MainActor
final class ResultPanelController: NSObject, NSWindowDelegate {

    private var panel: FloatingPanel?

    func show(_ record: ExecutionRecord) {
        let view = ExecutionResultView(record: record) { [weak self] in self?.hide() }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(16)
        present(view)
    }

    /// Shows a running/progress panel with a Cancel button. The panel is replaced by the
    /// result panel when the run finishes (including when cancelled).
    func showRunning(_ name: String, onCancel: @escaping () -> Void) {
        let view = RunningView(name: name, onCancel: onCancel)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(16)
        present(view)
    }

    private func present(_ view: some View) {
        let panel = panel ?? makePanel()
        self.panel = panel
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

/// A compact progress panel shown while a foreground command runs.
private struct RunningView: View {
    let name: String
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ProgressView().controlSize(.small)
            VStack(alignment: .leading, spacing: 1) {
                Text("Running…").font(.headline)
                Text(name).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 16)
            Button("Cancel", role: .cancel, action: onCancel)
                .keyboardShortcut(.cancelAction)
        }
        .padding(18)
        .frame(width: 360)
    }
}
