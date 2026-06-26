import AppKit
import Carbon.HIToolbox
import SwiftUI

/// A button-style control that records a new global hot key combination.
///
/// Click to enter recording mode; press any key + modifier to save; press Escape to cancel.
/// At least one modifier (⌘ ⌥ ⌃ ⇧) is required — bare key presses are ignored so the
/// recorder can't accidentally swallow normal typing.
struct HotKeyRecorderView: View {
    @Binding var preference: HotKeyPreference

    @State private var isRecording = false
    @State private var conflict = false
    private let minWidth: CGFloat = 160

    var body: some View {
        HStack(spacing: 6) {
            button
            if isRecording {
                Button("Cancel") { stopRecording() }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onDisappear { stopRecording() }
    }

    private var button: some View {
        Button(action: toggleRecording) {
            HStack(spacing: 6) {
                if isRecording {
                    ProgressView().controlSize(.mini)
                    Text("Press shortcut…")
                        .foregroundStyle(.secondary)
                } else if conflict {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Conflict — try another")
                        .foregroundStyle(.secondary)
                } else {
                    Text(preference.displayString)
                        .monospacedDigit()
                }
            }
            .frame(minWidth: minWidth, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .buttonStyle(.bordered)
        .overlay {
            if isRecording {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(.blue, lineWidth: 1.5)
            }
        }
    }

    // MARK: Recording

    private func toggleRecording() {
        if isRecording { stopRecording() } else { startRecording() }
    }

    @State private var monitor: Any?

    private func startRecording() {
        conflict = false
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            guard self.isRecording else { return event }

            // Escape cancels without changing the binding.
            if event.type == .keyDown, event.keyCode == UInt16(kVK_Escape) {
                self.stopRecording()
                return nil
            }

            // Ignore bare modifier-only events — wait for a real key.
            guard event.type == .keyDown else { return nil }

            let mods = carbonModifiers(from: event.modifierFlags)
            guard mods != 0 else { return nil }   // require at least one modifier

            let newPref = HotKeyPreference(keyCode: UInt32(event.keyCode), modifiers: mods)
            self.apply(newPref)
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
    }

    /// Applies the new preference, re-registers the system hotkey, and persists.
    /// Sets `conflict = true` if Carbon rejects the combination (already in use).
    private func apply(_ pref: HotKeyPreference) {
        // Probe registration — if it fails, another app has the combo.
        let probe = GlobalHotKey(keyCode: pref.keyCode, modifiers: pref.modifiers, action: {})
        if probe == nil {
            conflict = true
            stopRecording()
            return
        }
        // Discard probe immediately; AppDelegate will register the real handler.
        preference = pref
        pref.save()
        stopRecording()
        NotificationCenter.default.post(name: .hotKeyPreferenceDidChange, object: nil)
    }

    // MARK: Helpers

    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var mask: UInt32 = 0
        if flags.contains(.command) { mask |= UInt32(cmdKey) }
        if flags.contains(.option)  { mask |= UInt32(optionKey) }
        if flags.contains(.shift)   { mask |= UInt32(shiftKey) }
        if flags.contains(.control) { mask |= UInt32(controlKey) }
        return mask
    }
}

extension Notification.Name {
    static let hotKeyPreferenceDidChange = Notification.Name("relay.hotKeyPreferenceDidChange")
}
