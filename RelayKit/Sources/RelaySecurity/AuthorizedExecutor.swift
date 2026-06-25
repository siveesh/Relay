import Foundation
import RelayCore

/// A `CommandExecuting` decorator that handles elevation through macOS system authentication.
///
/// Relay never stores passwords. For commands that require elevation, this routes execution
/// through AppleScript's `do shell script … with administrator privileges`, which presents the
/// standard macOS authentication dialog (Touch ID where the user has it enabled). Non-elevated
/// commands pass straight through to the wrapped executor.
public struct AuthorizedExecutor: CommandExecuting {

    private let base: any CommandExecuting

    public init(base: any CommandExecuting) {
        self.base = base
    }

    public func run(_ command: RelayCommand) async throws -> CommandResult {
        guard command.requiresElevation else {
            return try await base.run(command)
        }

        // The whole script runs as root, so inline `sudo` is redundant — strip it.
        let script = command.command.replacingOccurrences(of: "sudo ", with: "")
        let appleScript = "do shell script \(Self.appleScriptString(script)) with administrator privileges"

        var elevated = command
        elevated.command = "/usr/bin/osascript -e \(Self.shellSingleQuoted(appleScript))"
        elevated.requiresElevation = false   // already wrapped; do not recurse
        return try await base.run(elevated)
    }

    /// Quotes a string as an AppleScript string literal (escaping `\` and `"`).
    static func appleScriptString(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }

    /// Wraps a string as a single POSIX-shell single-quoted token (robust against any content).
    static func shellSingleQuoted(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
