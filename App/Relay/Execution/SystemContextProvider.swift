import AppKit
import RelayCore

/// Supplies clipboard and Finder context for variable expansion, using AppKit and AppleScript.
struct SystemContextProvider: SystemContextProviding {

    func clipboardString() async -> String {
        NSPasteboard.general.string(forType: .string) ?? ""
    }

    func selectedFinderPaths() async -> [String] {
        let script = """
        tell application "Finder"
            set theItems to selection as alias list
            set output to ""
            repeat with anItem in theItems
                set output to output & POSIX path of anItem & linefeed
            end repeat
            return output
        end tell
        """
        return runAppleScript(script)
            .split(separator: "\n")
            .map { String($0) }
    }

    func currentFinderFolder() async -> String? {
        let script = """
        tell application "Finder"
            if (count of windows) is 0 then return ""
            return POSIX path of (target of front window as alias)
        end tell
        """
        let path = runAppleScript(script).trimmingCharacters(in: .whitespacesAndNewlines)
        return path.isEmpty ? nil : path
    }

    /// Runs an AppleScript via `osascript` and returns stdout (empty on error).
    private func runAppleScript(_ source: String) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", source]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            return String(decoding: data, as: UTF8.self)
        } catch {
            return ""
        }
    }
}
