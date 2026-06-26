import Foundation
import RelayCore
import RelayStorage
import RelaySearch
import RelaySecurity
import RelayNotifications
import RelayTasks
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

    /// The workflow/task library.
    let taskLibrary: TaskLibraryModel

    /// The execution-history log.
    let history: HistoryModel

    /// Coordinates execution (confirmation, variable resolution, logging, notifications, result).
    let runCoordinator: RunCoordinator

    init(
        commandStore: any CommandStoring,
        taskStore: any TaskStoring,
        historyStore: any HistoryStoring,
        search: any CommandSearching,
        executor: any CommandExecuting,
        notifications: any NotificationPosting,
        resolver: any VariableResolving
    ) {
        self.commandStore = commandStore
        self.search = search
        self.executor = executor
        self.notifications = notifications
        self.library = CommandLibraryModel(store: commandStore)
        self.taskLibrary = TaskLibraryModel(store: taskStore)
        self.history = HistoryModel(store: historyStore)

        let taskRunner = TaskRunner(executor: executor, notifications: notifications, resolver: resolver)
        self.runCoordinator = RunCoordinator(
            executor: executor,
            notifications: notifications,
            resolver: resolver,
            taskRunner: taskRunner,
            history: history
        )
    }

    /// The production environment: JSON-backed library + tasks + history on disk, seeded on
    /// first run. Elevation is handled by `AuthorizedExecutor` (macOS system auth, no stored
    /// passwords); variables resolve against live system context (clipboard, Finder).
    static func live() -> AppEnvironment {
        AppEnvironment(
            commandStore: JSONCommandStore(),
            taskStore: JSONTaskStore(),
            historyStore: JSONHistoryStore(),
            search: FuzzySearchEngine(),
            executor: AuthorizedExecutor(base: ShellExecutor()),
            notifications: NotificationService(),
            resolver: VariableResolver(
                custom: AppEnvironment.loadCustomVariables(),
                context: SystemContextProvider()
            )
        )
    }

    /// Reads the user's custom variable dictionary from UserDefaults.
    static func loadCustomVariables() -> [String: String] {
        UserDefaults.standard.dictionary(forKey: "relay.customVariables") as? [String: String] ?? [
            "NAS": "/Volumes/NAS",
            "CurrentProject": (NSHomeDirectory() as NSString).appendingPathComponent("Developer"),
        ]
    }

    /// Replaces the variable resolver with one using an updated custom-variable dictionary.
    /// Called whenever the user edits custom variables in Settings.
    func updateCustomVariables(_ custom: [String: String]) {
        let newResolver = VariableResolver(custom: custom, context: SystemContextProvider())
        runCoordinator.updateResolver(newResolver)
    }

    /// Builds a fresh palette view model bound to the current library and usage history.
    func makePaletteModel() -> CommandPaletteModel {
        let usage = UsageStats.from(history.records)
        return CommandPaletteModel(commands: library.commands, search: search, usage: usage)
    }
}
