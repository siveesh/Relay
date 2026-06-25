import Foundation

/// The outcome of executing a command.
public struct CommandResult: Sendable, Hashable {
    public let stdout: String
    public let stderr: String
    public let exitCode: Int32
    public let duration: TimeInterval

    public init(stdout: String, stderr: String, exitCode: Int32, duration: TimeInterval) {
        self.stdout = stdout
        self.stderr = stderr
        self.exitCode = exitCode
        self.duration = duration
    }

    /// A process exiting with status `0` is considered successful.
    public var succeeded: Bool { exitCode == 0 }
}

/// Errors raised by the execution engine before/around running a process.
public enum ExecutionError: Error, Sendable, Equatable {
    case shellNotFound(String)
    case timedOut(seconds: Int)
    case cancelled
    case launchFailed(String)
}
