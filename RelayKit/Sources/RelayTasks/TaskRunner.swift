import Foundation
import RelayCore
import RelayNotifications

/// The result of running a whole task.
public struct TaskRunResult: Sendable {
    public let outcomes: [StepOutcome]
    public let success: Bool
}

/// Reports progress as a workflow executes (optional; the runner also returns a full result).
public protocol TaskRunnerDelegate: AnyObject, Sendable {
    func taskRunner(willStart step: TaskStep, at index: Int)
    func taskRunner(didFinish outcome: StepOutcome, at index: Int)
}

/// Executes `RelayTask` workflows step by step, honouring retries, `continueOnError`, and the
/// task's `stopOnFailure` policy.
public actor TaskRunner {

    private let step: StepExecutor

    public init(
        executor: any CommandExecuting,
        notifications: any NotificationPosting,
        resolver: any VariableResolving,
        urlSession: URLSession = .shared
    ) {
        self.step = StepExecutor(
            executor: executor,
            notifications: notifications,
            resolver: resolver,
            urlSession: urlSession
        )
    }

    /// Runs the task's steps in order. Returns once the task completes, stops, or is cancelled.
    public func run(_ task: RelayTask, delegate: TaskRunnerDelegate? = nil) async -> TaskRunResult {
        var outcomes: [StepOutcome] = []
        var overallSuccess = true

        for (index, taskStep) in task.steps.enumerated() {
            if Task.isCancelled { break }
            delegate?.taskRunner(willStart: taskStep, at: index)

            let outcome = await runWithRetries(taskStep)
            outcomes.append(outcome)
            delegate?.taskRunner(didFinish: outcome, at: index)

            if !outcome.success {
                overallSuccess = false
                // Stop the whole task unless this step opts to continue, or the task allows it.
                if task.stopOnFailure && !taskStep.continueOnError {
                    break
                }
            }
        }

        return TaskRunResult(outcomes: outcomes, success: overallSuccess)
    }

    /// Performs one step, retrying up to `retryCount` additional times on failure.
    private func runWithRetries(_ taskStep: TaskStep) async -> StepOutcome {
        var lastError: Error?
        let attempts = max(0, taskStep.retryCount) + 1

        for attempt in 0..<attempts {
            if Task.isCancelled {
                return StepOutcome(id: taskStep.id, success: false, message: "Cancelled")
            }
            do {
                try await step.perform(taskStep)
                return StepOutcome(id: taskStep.id, success: true, message: "OK")
            } catch {
                lastError = error
                // Brief backoff before retrying.
                if attempt < attempts - 1 {
                    try? await Task.sleep(for: .milliseconds(300))
                }
            }
        }

        return StepOutcome(id: taskStep.id, success: false, message: Self.describe(lastError))
    }

    private static func describe(_ error: Error?) -> String {
        switch error {
        case let stepError as StepError:
            switch stepError {
            case let .nonZeroExit(code, stderr):
                return "Exit \(code)\(stderr.isEmpty ? "" : ": \(stderr.prefix(120))")"
            case let .healthCheckFailed(status, expected):
                return "HTTP \(status), expected \(expected)"
            case .conditionNotMet:
                return "Condition not met"
            }
        case let error?:
            return error.localizedDescription
        case nil:
            return "Unknown error"
        }
    }
}
