import Foundation

/// A single executable command in the Relay library.
///
/// `RelayCommand` is a pure value type (`Sendable`) so it can cross actor and task
/// boundaries freely. It is the canonical model persisted to disk and rendered in the UI.
public struct RelayCommand: Identifiable, Codable, Hashable, Sendable {

    /// Stable internal identity. Generated for user-created commands; preserved across
    /// import/export. (Imported packs that use slug ids are mapped to UUIDs on import.)
    public var id: UUID

    // MARK: Presentation

    public var name: String
    public var details: String
    public var category: String
    /// SF Symbol name used as the command's glyph.
    public var icon: String
    public var tags: [String]
    public var aliases: [String]

    // MARK: Execution

    /// Shell used to run the command, e.g. `"zsh"` or `"bash"`. Resolved to `/bin/<shell>`.
    public var shell: String
    /// Working directory. May contain `~` or Relay variables; resolved at execution time.
    public var workingDirectory: String
    /// Extra environment variables layered on top of the user's environment.
    public var environment: [String: String]
    /// The command text passed to the shell via `-lc`.
    public var command: String
    /// Hard timeout in seconds. `0` means no timeout.
    public var timeoutSeconds: Int

    // MARK: Behaviour flags

    public var requiresConfirmation: Bool
    public var requiresElevation: Bool
    public var runInBackground: Bool
    public var captureOutput: Bool
    public var notifyOnCompletion: Bool

    // MARK: Discovery

    /// Optional per-command keyboard shortcut (human-readable, e.g. `"⌘⇧D"`).
    public var keyboardShortcut: String?
    public var favorite: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        details: String = "",
        category: String = "General",
        icon: String = "chevron.right.circle.fill",
        tags: [String] = [],
        aliases: [String] = [],
        shell: String = "zsh",
        workingDirectory: String = "~",
        environment: [String: String] = [:],
        command: String,
        timeoutSeconds: Int = 60,
        requiresConfirmation: Bool = false,
        requiresElevation: Bool = false,
        runInBackground: Bool = false,
        captureOutput: Bool = true,
        notifyOnCompletion: Bool = false,
        keyboardShortcut: String? = nil,
        favorite: Bool = false
    ) {
        self.id = id
        self.name = name
        self.details = details
        self.category = category
        self.icon = icon
        self.tags = tags
        self.aliases = aliases
        self.shell = shell
        self.workingDirectory = workingDirectory
        self.environment = environment
        self.command = command
        self.timeoutSeconds = timeoutSeconds
        self.requiresConfirmation = requiresConfirmation
        self.requiresElevation = requiresElevation
        self.runInBackground = runInBackground
        self.captureOutput = captureOutput
        self.notifyOnCompletion = notifyOnCompletion
        self.keyboardShortcut = keyboardShortcut
        self.favorite = favorite
    }
}

extension RelayCommand {
    /// Custom coding keys: the on-disk field is `description` (per the spec / sample packs),
    /// while the Swift property is `details` to avoid clashing with `CustomStringConvertible`.
    enum CodingKeys: String, CodingKey {
        case id, name
        case details = "description"
        case category, icon, tags, aliases, shell, workingDirectory, environment, command
        case timeoutSeconds, requiresConfirmation, requiresElevation, runInBackground
        case captureOutput, notifyOnCompletion, keyboardShortcut, favorite
    }
}
