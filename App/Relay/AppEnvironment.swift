import Foundation
import RelayCore
import RelayStorage
import RelaySearch
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

    /// Synchronous snapshot of the library for UI that needs it immediately (menu bar,
    /// palette). Replaced by store-driven loading in Milestone 2.
    private(set) var commands: [RelayCommand]

    init(
        commandStore: any CommandStoring,
        search: any CommandSearching,
        executor: any CommandExecuting,
        notifications: any NotificationPosting,
        seedCommands: [RelayCommand]
    ) {
        self.commandStore = commandStore
        self.search = search
        self.executor = executor
        self.notifications = notifications
        self.commands = seedCommands
    }

    /// The production environment for Milestone 1: in-memory sample library.
    static func live() -> AppEnvironment {
        AppEnvironment(
            commandStore: InMemoryCommandStore(seed: RelayCommand.samples),
            search: FuzzySearchEngine(),
            executor: ShellExecutor(),
            notifications: NotificationService(),
            seedCommands: RelayCommand.samples
        )
    }

    /// Builds a fresh palette view model bound to the current library.
    func makePaletteModel() -> CommandPaletteModel {
        CommandPaletteModel(commands: commands, search: search)
    }
}
