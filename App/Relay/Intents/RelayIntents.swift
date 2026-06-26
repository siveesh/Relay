import AppIntents
import Foundation
import RelayCore
import RelayStorage

// MARK: - Entity

/// Represents a single Relay command as an AppIntents entity so Shortcuts can pick one.
@available(macOS 13.0, *)
struct RelayCommandEntity: AppEntity, Sendable {
    nonisolated(unsafe) static var typeDisplayRepresentation: TypeDisplayRepresentation = "Relay Command"
    nonisolated(unsafe) static var defaultQuery = RelayCommandEntityQuery()

    var id: UUID
    var name: String
    var category: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(category)")
    }
}

@available(macOS 13.0, *)
extension RelayCommand {
    var shortcutEntity: RelayCommandEntity {
        RelayCommandEntity(id: id, name: name, category: category)
    }
}

// MARK: - Query

@available(macOS 13.0, *)
struct RelayCommandEntityQuery: EntityQuery, Sendable {

    func entities(for identifiers: [UUID]) async throws -> [RelayCommandEntity] {
        try await allCommands().filter { identifiers.contains($0.id) }.map(\.shortcutEntity)
    }

    func suggestedEntities() async throws -> [RelayCommandEntity] {
        try await allCommands().map(\.shortcutEntity)
    }

    private func allCommands() async throws -> [RelayCommand] {
        let store = JSONCommandStore()
        return (try? await store.loadCommands()) ?? RelayCommand.samples
    }
}

// MARK: - Run Command Intent

/// Lets Shortcuts and Siri run any command from the Relay library.
@available(macOS 13.0, *)
struct RunRelayCommandIntent: AppIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "Run Relay Command"
    nonisolated(unsafe) static var description = IntentDescription(
        "Run a saved command from your Relay library.",
        categoryName: "Relay"
    )
    nonisolated(unsafe) static var openAppWhenRun: Bool = false

    @Parameter(title: "Command", description: "The command to run from your Relay library.")
    var command: RelayCommandEntity

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = JSONCommandStore()
        let commands = (try? await store.loadCommands()) ?? RelayCommand.samples
        guard let fullCommand = commands.first(where: { $0.id == command.id }) else {
            throw RelayIntentError.commandNotFound
        }

        let executor = ShellExecutor()
        let result = try await executor.run(fullCommand)
        let output = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        let err = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = output.isEmpty ? (err.isEmpty ? "Completed (exit \(result.exitCode))." : err) : output

        return .result(dialog: IntentDialog(stringLiteral: String(body.prefix(500))))
    }
}

// MARK: - Search Commands Intent

@available(macOS 13.0, *)
struct SearchRelayCommandsIntent: AppIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "Search Relay Commands"
    nonisolated(unsafe) static var description = IntentDescription(
        "Find commands in your Relay library matching a search term.",
        categoryName: "Relay"
    )
    nonisolated(unsafe) static var openAppWhenRun: Bool = false

    @Parameter(title: "Search Term")
    var query: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = JSONCommandStore()
        let commands = (try? await store.loadCommands()) ?? RelayCommand.samples
        let lower = query.lowercased()
        let matches = commands.filter {
            $0.name.lowercased().contains(lower) ||
            $0.category.lowercased().contains(lower) ||
            $0.tags.contains { $0.lowercased().contains(lower) }
        }
        if matches.isEmpty {
            return .result(dialog: IntentDialog(stringLiteral: "No commands match \"\(query)\"."))
        }
        let list = matches.prefix(10).map { "• \($0.name) (\($0.category))" }.joined(separator: "\n")
        return .result(dialog: IntentDialog(stringLiteral: list))
    }
}

// MARK: - Open Palette Intent

@available(macOS 13.0, *)
struct OpenRelayPaletteIntent: AppIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "Open Relay Palette"
    nonisolated(unsafe) static var description = IntentDescription(
        "Open the Relay command palette.",
        categoryName: "Relay"
    )
    nonisolated(unsafe) static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            NotificationCenter.default.post(name: .openPaletteFromIntent, object: nil)
        }
        return .result()
    }
}

// MARK: - App Shortcuts

@available(macOS 13.0, *)
struct RelayAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenRelayPaletteIntent(),
            phrases: ["Open \(.applicationName)", "Show \(.applicationName) palette"],
            shortTitle: "Open Palette",
            systemImageName: "chevron.right.2"
        )
        AppShortcut(
            intent: RunRelayCommandIntent(),
            phrases: [
                "Run \(\.$command) with \(.applicationName)",
                "Execute \(\.$command) in \(.applicationName)",
            ],
            shortTitle: "Run Command",
            systemImageName: "play.circle"
        )
    }
}

// MARK: - Errors

@available(macOS 13.0, *)
enum RelayIntentError: Error, CustomLocalizedStringResourceConvertible {
    case commandNotFound

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .commandNotFound: return "The selected command could not be found in your Relay library."
        }
    }
}

// MARK: - Notification bridge

extension Notification.Name {
    static let openPaletteFromIntent = Notification.Name("relay.openPaletteFromIntent")
}
