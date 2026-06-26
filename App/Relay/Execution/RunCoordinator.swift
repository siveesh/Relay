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
    /// Name of the command/task currently executing (for progress UI).
    private(set) var runningName: String?

    private let executor: any CommandExecuting
    private let notifications: any NotificationPosting
    private let resolver: any VariableResolving
    private let taskRunner: TaskRunner
    let history: HistoryModel

    /// The in-flight execution task, retained so it can be cancelled.
    private var currentTask: Task<Void, Never>?

    /// Presentation hook set by the app delegate to show a result panel.
    var onResult: ((ExecutionRecord) -> Void)?
    /// Called when a foreground command starts, so a progress/cancel panel can be shown.
    /// The running panel is later replaced by the result panel via `onResult`.
    var onRunningStarted: ((String) -> Void)?

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
        currentTask = Task { await run(command) }
    }

    /// Cancels the in-flight command (terminates the process via the executor).
    func cancelCurrent() {
        currentTask?.cancel()
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
        runningName = command.name
        // Foreground commands show a progress/cancel panel; background ones run silently.
        if !command.runInBackground { onRunningStarted?(command.name) }
        defer {
            isRunning = false
            runningName = nil
        }

        let resolvedCommand = await resolve(command)
        let startedAt = Date()

        var cancelled = false
        let record: ExecutionRecord
        do {
            let result = try await executor.run(resolvedCommand)
            record = ExecutionRecord.from(result, command: command, startedAt: startedAt)
        } catch let error as ExecutionError where error == .cancelled {
            cancelled = true
            record = ExecutionRecord.failure("Cancelled", command: command, startedAt: startedAt)
        } catch {
            record = ExecutionRecord.failure(error.localizedDescription, command: command, startedAt: startedAt)
        }

        history.append(record)
        await notify(command: command, record: record, cancelled: cancelled)

        // Foreground runs replace the progress panel with the result (shows "No output" if
        // empty); background runs stay silent.
        if !command.runInBackground {
            onResult?(record)
        }
    }

    /// Posts the appropriate notification category for the outcome.
    private func notify(command: RelayCommand, record: ExecutionRecord, cancelled: Bool) async {
        guard command.notifyOnCompletion else { return }
        if cancelled {
            await notifications.post(.cancelled(title: command.name, body: "Execution cancelled."))
        } else if record.succeeded && !record.stderr.isEmpty {
            // Exit 0 but wrote to stderr → completed with warnings.
            await notifications.post(.warning(title: command.name, body: "Completed with warnings."))
        } else if record.succeeded {
            await notifications.post(.completed(title: command.name, body: "Completed successfully."))
        } else {
            await notifications.post(.failed(title: command.name, body: "Finished with errors."))
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
