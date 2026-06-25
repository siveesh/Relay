import Foundation
import RelayCore
import RelayNotifications

/// The outcome of a single workflow step.
public struct StepOutcome: Identifiable, Sendable {
    public let id: UUID
    public let success: Bool
    public let message: String
}

/// Errors a step can raise.
public enum StepError: Error, Sendable, Equatable {
    case nonZeroExit(Int32, stderr: String)
    case healthCheckFailed(status: Int, expected: Int)
    case conditionNotMet
}

/// Executes a single `TaskStep`. Pure logic; all side-effecting capabilities are injected.
struct StepExecutor {

    let executor: any CommandExecuting
    let notifications: any NotificationPosting
    let resolver: any VariableResolving
    let urlSession: URLSession

    /// Runs one step's action once (no retry — that is the runner's responsibility).
    func perform(_ step: TaskStep) async throws {
        switch step.kind {
        case let .shell(command, shell):
            try await runShell(command: command, shell: shell)

        case let .launchApp(bundleIdentifier):
            try await runShell(command: "open -b \(quoted(bundleIdentifier))", shell: "zsh")

        case let .quitApp(bundleIdentifier):
            let script = "tell application id \(quoted(bundleIdentifier)) to quit"
            try await runShell(command: "osascript -e \(quoted(script))", shell: "zsh")

        case let .delay(seconds):
            try await Task.sleep(for: .seconds(seconds))

        case let .waitUntil(condition):
            try await runShell(command: condition, shell: "zsh")   // success == exit 0

        case let .httpHealthCheck(url, expectedStatus):
            try await healthCheck(url: url, expected: expectedStatus)

        case let .appleScript(source):
            let resolved = await resolver.resolve(source)
            try await runShell(command: "osascript -e \(quoted(resolved))", shell: "zsh")

        case let .javaScriptForAutomation(source):
            let resolved = await resolver.resolve(source)
            try await runShell(command: "osascript -l JavaScript -e \(quoted(resolved))", shell: "zsh")

        case let .notify(title, body):
            await notifications.post(.completed(title: await resolver.resolve(title),
                                                body: await resolver.resolve(body)))
        }
    }

    // MARK: Helpers

    private func runShell(command: String, shell: String) async throws {
        let resolved = await resolver.resolve(command)
        let relayCommand = RelayCommand(name: "step", shell: shell, command: resolved, timeoutSeconds: 0)
        let result = try await executor.run(relayCommand)
        guard result.succeeded else {
            throw StepError.nonZeroExit(result.exitCode, stderr: result.stderr)
        }
    }

    private func healthCheck(url urlString: String, expected: Int) async throws {
        let resolved = await resolver.resolve(urlString)
        guard let url = URL(string: resolved) else {
            throw StepError.healthCheckFailed(status: -1, expected: expected)
        }
        let (_, response) = try await urlSession.data(from: url)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard status == expected else {
            throw StepError.healthCheckFailed(status: status, expected: expected)
        }
    }

    /// POSIX single-quote a token robustly.
    private func quoted(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
