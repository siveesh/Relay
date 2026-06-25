import AppKit
import Observation
import RelayCore
import RelayNotifications
import RelayTasks

/// Coordinates command and task execution: confirmation, variable resolution, running, history
/// logging, notifications, and surfacing the result. Single entry point for palette and menu.
@MainActor
@Observable
final class RunCoordinator {

    private(set) var isRunning = false

    private let executor: any CommandExecuting
    private let notifications: any NotificationPosting
    private let resolver: any VariableResolving
    private let taskRunner: TaskRunner
    let history: HistoryModel

    /// Presentation hook set by the app delegate to show a result panel.
    var onResult: ((ExecutionRecord) -> Void)?

    init(
        executor: any CommandExecuting,
        notifications: any NotificationPosting,
        resolver: any VariableResolving,
        taskRunner: TaskRunner,
        history: HistoryModel
    ) {
        self.executor = executor
        self.notifications = notifications
        self.resolver = resolver
        self.taskRunner = taskRunner
        self.history = history
    }

    /// Public entry point: asks for confirmation if required, then runs.
    func requestRun(_ command: RelayCommand) {
        if command.requiresConfirmation, !confirm(command) { return }
        Task { await run(command) }
    }

    /// Runs a workflow task, posting a summary notification on completion.
    func requestRun(_ task: RelayTask) {
        Task {
            isRunning = true
            defer { isRunning = false }
            let result = await taskRunner.run(task)
            let failures = result.outcomes.filter { !$0.success }.count
            await notifications.post(
                result.success
                    ? .completed(title: task.name, body: "Workflow completed.")
                    : .failed(title: task.name, body: "\(failures) step(s) failed.")
            )
        }
    }

    private func run(_ command: RelayCommand) async {
        isRunning = true
        defer { isRunning = false }

        let resolvedCommand = await resolve(command)
        let startedAt = Date()
        let record: ExecutionRecord
        do {
            let result = try await executor.run(resolvedCommand)
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

    /// Expands Relay variables in the command text, working directory, and environment.
    private func resolve(_ command: RelayCommand) async -> RelayCommand {
        var resolved = command
        resolved.command = await resolver.resolve(command.command)
        resolved.workingDirectory = await resolver.resolve(command.workingDirectory)
        var environment: [String: String] = [:]
        for (key, value) in command.environment {
            environment[key] = await resolver.resolve(value)
        }
        resolved.environment = environment
        return resolved
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
