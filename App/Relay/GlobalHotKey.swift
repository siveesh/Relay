import AppKit
import Carbon.HIToolbox

/// Registers a single system-wide hot key via the Carbon Hot Keys API.
///
/// Carbon remains the only reliable way to register a global shortcut on macOS, and it
/// delivers events on the main run loop. Its callback is a context-free C function pointer,
/// so registered actions and hot-key refs are kept in static tables keyed by id.
@MainActor
final class GlobalHotKey {

    private let identifier: UInt32

    // The Carbon callback cannot capture Swift context, so state is stored here and looked up
    // by hot-key id. Carbon delivers on the main thread; the callback hops to the main actor
    // via `assumeIsolated` before invoking an action.
    nonisolated(unsafe) private static var actions: [UInt32: @MainActor () -> Void] = [:]
    nonisolated(unsafe) private static var refs: [UInt32: EventHotKeyRef] = [:]
    nonisolated(unsafe) private static var nextIdentifier: UInt32 = 1
    nonisolated(unsafe) private static var handlerInstalled = false

    /// Four-char-code signature ('RELY') identifying Relay's hot keys.
    private static let signature: OSType = {
        Array("RELY".utf8).reduce(OSType(0)) { ($0 << 8) + OSType($1) }
    }()

    /// - Parameters:
    ///   - keyCode: a virtual key code, e.g. `kVK_Space`.
    ///   - modifiers: a Carbon modifier mask, e.g. `UInt32(optionKey)`.
    ///   - action: invoked on the main actor when the hot key is pressed.
    init?(keyCode: UInt32, modifiers: UInt32, action: @escaping @MainActor () -> Void) {
        self.identifier = Self.nextIdentifier
        Self.nextIdentifier += 1
        Self.actions[identifier] = action
        Self.installHandlerIfNeeded()

        let hotKeyID = EventHotKeyID(signature: Self.signature, id: identifier)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode, modifiers, hotKeyID,
            GetEventDispatcherTarget(), 0, &ref
        )

        guard status == noErr, let ref else {
            Self.actions[identifier] = nil
            return nil
        }
        Self.refs[identifier] = ref
    }

    deinit {
        // Touches only the immutable `identifier` and the static tables, so this is valid from
        // the nonisolated deinit of a `@MainActor` type.
        if let ref = GlobalHotKey.refs[identifier] {
            UnregisterEventHotKey(ref)
            GlobalHotKey.refs[identifier] = nil
        }
        GlobalHotKey.actions[identifier] = nil
    }

    private static func installHandlerIfNeeded() {
        guard !handlerInstalled else { return }
        handlerInstalled = true

        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, event, _ -> OSStatus in
                guard let event else { return OSStatus(eventNotHandledErr) }
                var hotKeyID = EventHotKeyID()
                let err = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                guard err == noErr else { return err }
                // Carbon delivers hot-key events on the main thread.
                MainActor.assumeIsolated {
                    GlobalHotKey.actions[hotKeyID.id]?()
                }
                return noErr
            },
            1, &eventSpec, nil, nil
        )
    }
}
