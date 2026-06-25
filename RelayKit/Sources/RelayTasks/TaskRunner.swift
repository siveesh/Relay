import Foundation
import RelayCore

/// Reports progress as a workflow executes.
public protocol TaskRunnerDelegate: AnyObject, Sendable {
    func taskRunner(didStart step: TaskStep, at index: Int)
    func taskRunner(didFinish step: TaskStep, at index: Int, success: Bool)
}

/// Executes `RelayTask` workflows step by step.
///
/// > Milestone note: this is the M1 architectural seam. Step execution, retries, conditional
/// > branching, and health checks are implemented in Milestone 5. The shape (an `actor`
/// > driving an injected executor) is fixed now so the rest of the app can depend on it.
public actor TaskRunner {

    private let executor: any CommandExecuting

    public init(executor: any CommandExecuting) {
        self.executor = executor
    }

    /// Runs the task's steps in order. Currently a placeholder that validates wiring.
    public func run(_ task: RelayTask) async throws {
        _ = executor
        _ = task
        // Implemented in Milestone 5.
    }
}
