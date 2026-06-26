import Carbon.HIToolbox
import Foundation

/// Persisted representation of the global palette hot key.
struct HotKeyPreference: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32  // Carbon modifier mask (cmdKey, optionKey, …)

    static let `default` = HotKeyPreference(
        keyCode: UInt32(kVK_Space),
        modifiers: UInt32(optionKey)
    )
    static let userDefaultsKey = "relay.globalHotKey"

    static func load() -> HotKeyPreference {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let pref = try? JSONDecoder().decode(HotKeyPreference.self, from: data)
        else { return .default }
        return pref
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
        }
    }

    /// Human-readable representation using standard macOS modifier symbols.
    var displayString: String {
        modifierSymbols + keyDisplayName
    }

    private var modifierSymbols: String {
        var s = ""
        if modifiers & UInt32(controlKey) != 0 { s += "⌃" }
        if modifiers & UInt32(optionKey)  != 0 { s += "⌥" }
        if modifiers & UInt32(shiftKey)   != 0 { s += "⇧" }
        if modifiers & UInt32(cmdKey)     != 0 { s += "⌘" }
        return s
    }

    private var keyDisplayName: String {
        switch Int(keyCode) {
        case kVK_Space:           return "Space"
        case kVK_Return:          return "↩"
        case kVK_Tab:             return "⇥"
        case kVK_Delete:          return "⌫"
        case kVK_ForwardDelete:   return "⌦"
        case kVK_Escape:          return "⎋"
        case kVK_UpArrow:         return "↑"
        case kVK_DownArrow:       return "↓"
        case kVK_LeftArrow:       return "←"
        case kVK_RightArrow:      return "→"
        case kVK_Home:            return "↖"
        case kVK_End:             return "↘"
        case kVK_PageUp:          return "⇞"
        case kVK_PageDown:        return "⇟"
        case kVK_F1:              return "F1"
        case kVK_F2:              return "F2"
        case kVK_F3:              return "F3"
        case kVK_F4:              return "F4"
        case kVK_F5:              return "F5"
        case kVK_F6:              return "F6"
        case kVK_F7:              return "F7"
        case kVK_F8:              return "F8"
        case kVK_F9:              return "F9"
        case kVK_F10:             return "F10"
        case kVK_F11:             return "F11"
        case kVK_F12:             return "F12"
        default:                  return characterName(for: keyCode)
        }
    }

    /// Translates a virtual key code to its unshifted character using the current keyboard layout.
    private func characterName(for keyCode: UInt32) -> String {
        let source = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        guard let layoutData = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
            return "(\(keyCode))"
        }
        let layout = unsafeBitCast(layoutData, to: CFData.self)
        let keyboardLayout = unsafeBitCast(CFDataGetBytePtr(layout), to: UnsafePointer<UCKeyboardLayout>.self)

        var deadKeyState: UInt32 = 0
        var length = 0
        var chars = [UniChar](repeating: 0, count: 4)
        let status = UCKeyTranslate(
            keyboardLayout,
            UInt16(keyCode),
            UInt16(kUCKeyActionDisplay),
            0,
            UInt32(LMGetKbdType()),
            OptionBits(kUCKeyTranslateNoDeadKeysMask),
            &deadKeyState,
            4,
            &length,
            &chars
        )
        guard status == noErr, length > 0 else { return "(\(keyCode))" }
        return String(chars[0..<length].map { Character(UnicodeScalar($0)!) })
            .uppercased()
    }
}
