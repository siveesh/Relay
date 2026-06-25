import Foundation

/// Supplies system/environment values that variable expansion needs but that `RelayCore`
/// cannot read on its own (clipboard, Finder selection). The app provides a concrete
/// implementation; the default returns empty values.
public protocol SystemContextProviding: Sendable {
    func clipboardString() async -> String
    func selectedFinderPaths() async -> [String]
    func currentFinderFolder() async -> String?
}

/// A no-op provider used by default and in tests.
public struct EmptySystemContext: SystemContextProviding {
    public init() {}
    public func clipboardString() async -> String { "" }
    public func selectedFinderPaths() async -> [String] { [] }
    public func currentFinderFolder() async -> String? { nil }
}

/// Expands Relay variables (`$Desktop`, `$Clipboard`, `$Date`, custom names, …) inside command
/// text, working directories, and environment values.
public struct VariableResolver: VariableResolving {

    private let custom: [String: String]
    private let context: any SystemContextProviding
    private let now: @Sendable () -> Date

    public init(
        custom: [String: String] = [:],
        context: any SystemContextProviding = EmptySystemContext(),
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.custom = custom
        self.context = context
        self.now = now
    }

    /// The set of variable names Relay recognizes (excluding user-defined ones).
    public static let builtinNames = [
        "Home", "Desktop", "Downloads", "Documents",
        "Clipboard", "SelectedFinderFiles", "CurrentFinderFolder", "CurrentProject", "NAS",
        "Date", "Time", "Hostname", "Username"
    ]

    public func resolve(_ input: String) async -> String {
        guard input.contains("$") else { return input }

        // Match `$Name` tokens (letters/digits/underscore).
        let pattern = try! NSRegularExpression(pattern: "\\$([A-Za-z_][A-Za-z0-9_]*)")
        let nsInput = input as NSString
        let matches = pattern.matches(in: input, range: NSRange(location: 0, length: nsInput.length))

        // Resolve each distinct name once, then substitute back-to-front to keep ranges valid.
        var result = input
        for match in matches.reversed() {
            let name = nsInput.substring(with: match.range(at: 1))
            guard let value = await value(for: name) else { continue }   // leave unknowns intact
            let fullRange = Range(match.range, in: result)!
            result.replaceSubrange(fullRange, with: value)
        }
        return result
    }

    private func value(for name: String) async -> String? {
        switch name {
        case "Home": return NSHomeDirectory()
        case "Desktop": return directory(.desktopDirectory)
        case "Downloads": return directory(.downloadsDirectory)
        case "Documents": return directory(.documentDirectory)
        case "Clipboard": return await context.clipboardString()
        case "SelectedFinderFiles":
            return await context.selectedFinderPaths()
                .map { "'\($0)'" }
                .joined(separator: " ")
        case "CurrentFinderFolder": return await context.currentFinderFolder() ?? ""
        case "CurrentProject": return custom["CurrentProject"] ?? ""
        case "NAS": return custom["NAS"] ?? ""
        case "Date": return formatted("yyyy-MM-dd")
        case "Time": return formatted("HH:mm:ss")
        case "Hostname": return ProcessInfo.processInfo.hostName
        case "Username": return NSUserName()
        default: return custom[name]   // user-defined; nil leaves the token untouched
        }
    }

    private func directory(_ directory: FileManager.SearchPathDirectory) -> String {
        FileManager.default.urls(for: directory, in: .userDomainMask).first?.path ?? NSHomeDirectory()
    }

    private func formatted(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        return formatter.string(from: now())
    }
}
