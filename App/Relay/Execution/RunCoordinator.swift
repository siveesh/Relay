import AppKit
import Observation
import RelayCore
import RelayNotifications

/// Coordinates command execution: confirmation, running, history logging, notifications, and
/// surfacing the result. This is the single entry point both the palette and the menu use.
@MainActor
@Observable
final class RunCoordinator {

    private(set) var isRunning = false

    private let executor: any CommandExecuting
    private let notifications: any NotificationPosting
    let history: HistoryModel

    /// Presentation hook set by the app delegate to show a result panel.
    var onResult: ((ExecutionRecord) -> Void)?

    init(executor: any CommandExecuting, notifications: any NotificationPosting, history: HistoryModel) {
        self.executor = executor
        self.notifications = notifications
        self.history = history
    }

    /// Public entry point: asks for confirmation if required, then runs.
    func requestRun(_ command: RelayCommand) {
        if command.requiresConfirmation, !confirm(command) { return }
        Task { await run(command) }
    }

    private func run(_ command: RelayCommand) async {
        isRunning = true
        defer { isRunning = false }

        let startedAt = Date()
        let record: ExecutionRecord
        do {
            let result = try await executor.run(command)
            record = ExecutionRecord.from(result, command: command, startedAt: startedAt)
        } catch {
            record = ExecutionRecord.failure(error.localizedDescription, command: command, startedAt: startedAt)
        }

        history.append(record)

        if command.notifyOnCompletion {
            let summary = record.succeeded ? "Completed successfully" : "Finished with errors"
            await notifications.post(
                record.succeeded
                    ? .completed(title: command.name, body: summary)
                    : .failed(title: command.name, body: summary)
            )
        }

        // Only surface a result window when there is something to show or it failed.
        if command.captureOutput || !record.succeeded {
            onResult?(record)
        }
    }

    /// Modal confirmation before running a command that requires it.
    private func confirm(_ command: RelayCommand) -> Bool {
        let alert = NSAlert()
        alert.messageText = "Run “\(command.name)”?"
        alert.informativeText = command.requiresElevation
            ? "This command requires administrator privileges.\n\n\(command.command)"
            : command.command
        alert.alertStyle = command.requiresElevation ? .warning : .informational
        alert.addButton(withTitle: "Run")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn
    }
}
