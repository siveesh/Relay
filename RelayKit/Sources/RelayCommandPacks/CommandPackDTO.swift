import Foundation
import RelayCore

/// Lenient wire format for imported command packs.
///
/// External packs (including Relay's starter pack) identify commands with human-readable
/// *slugs* and may omit fields. This DTO decodes that forgiving shape, then maps each command
/// to a `RelayCommand` with a stable slug-derived UUID. Relay's own on-disk library, by
/// contrast, uses the strict `RelayCommand` codable with real UUIDs.
struct CommandPackDTO: Decodable {
    var packName: String?
    var version: String?
    var commands: [CommandDTO]
}

struct CommandDTO: Decodable {
    var id: String?
    var name: String
    var description: String?
    var category: String?
    var icon: String?
    var tags: [String]?
    var aliases: [String]?
    var shell: String?
    var workingDirectory: String?
    var environment: [String: String]?
    var command: String
    var timeoutSeconds: Int?
    var requiresConfirmation: Bool?
    var requiresElevation: Bool?
    var runInBackground: Bool?
    var captureOutput: Bool?
    var notifyOnCompletion: Bool?
    var keyboardShortcut: String?
    var favorite: Bool?

    /// Converts the DTO into a `RelayCommand`, deriving a stable id from the slug when present.
    func toCommand() -> RelayCommand {
        let resolvedID: UUID = {
            if let id, let uuid = UUID(uuidString: id) { return uuid }   // already a UUID
            if let id, !id.isEmpty { return UUID(namespacedSlug: id) }   // slug → stable UUID
            return UUID(namespacedSlug: name)                            // fall back to name
        }()

        return RelayCommand(
            id: resolvedID,
            name: name,
            details: description ?? "",
            category: category ?? "General",
            icon: icon ?? "chevron.right.circle.fill",
            tags: tags ?? [],
            aliases: aliases ?? [],
            shell: shell ?? "zsh",
            workingDirectory: workingDirectory ?? "~",
            environment: environment ?? [:],
            command: command,
            timeoutSeconds: timeoutSeconds ?? 60,
            requiresConfirmation: requiresConfirmation ?? false,
            requiresElevation: requiresElevation ?? false,
            runInBackground: runInBackground ?? false,
            captureOutput: captureOutput ?? true,
            notifyOnCompletion: notifyOnCompletion ?? false,
            keyboardShortcut: keyboardShortcut,
            favorite: favorite ?? false
        )
    }
}
