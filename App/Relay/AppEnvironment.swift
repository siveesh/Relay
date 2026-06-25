import Foundation
import RelayCore
import RelayStorage
import RelaySearch
import RelaySecurity
import RelayNotifications
import RelayUI

/// The application's composition root.
///
/// Constructs and holds the concrete services, injecting them wherever they are needed. This
/// is the single place that knows about concrete types; everything else depends on protocols.
@MainActor
final class AppEnvironment {

    let commandStore: any CommandStoring
    let search: any CommandSearching
    let executor: any CommandExecuting
    let notifications: any NotificationPosting

    /// The single source of truth for the command library (loaded from `commandStore`).
    let library: CommandLibraryModel

    /// The execution-history log.
    let history: HistoryModel

    /// Coordinates execution (confirmation, running, logging, notifications, result display).
    let runCoordinator: RunCoordinator

    init(
        commandStore: any CommandStoring,
        historyStore: any HistoryStoring,
        search: any CommandSearching,
        executor: any CommandExecuting,
        notifications: any NotificationPosting
    ) {
        self.commandStore = commandStore
        self.search = search
        self.executor = executor
        self.notifications = notifications
        self.library = CommandLibraryModel(store: commandStore)
        self.history = HistoryModel(store: historyStore)
        self.runCoordinator = RunCoordinator(executor: executor, notifications: notifications, history: history)
    }

    /// The production environment: JSON-backed library + history on disk, seeded on first run.
    /// Elevation is handled by `AuthorizedExecutor` (macOS system auth, no stored passwords).
    static func live() -> AppEnvironment {
        AppEnvironment(
            commandStore: JSONCommandStore(),
            historyStore: JSONHistoryStore(),
            search: FuzzySearchEngine(),
            executor: AuthorizedExecutor(base: ShellExecutor()),
            notifications: NotificationService()
        )
    }

    /// Builds a fresh palette view model bound to the current library.
    func makePaletteModel() -> CommandPaletteModel {
        CommandPaletteModel(commands: library.commands, search: search)
    }
}
