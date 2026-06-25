import Foundation

/// A persisted record of a single command execution, used for the history log.
public struct ExecutionRecord: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var commandID: UUID
    public var commandName: String
    public var startedAt: Date
    public var duration: TimeInterval
    public var exitCode: Int32
    public var stdout: String
    public var stderr: String
    /// Set when execution failed to start or was cancelled/timed out (no clean exit code).
    public var failureMessage: String?

    public init(
        id: UUID = UUID(),
        commandID: UUID,
        commandName: String,
        startedAt: Date,
        duration: TimeInterval,
        exitCode: Int32,
        stdout: String,
        stderr: String,
        failureMessage: String? = nil
    ) {
        self.id = id
        self.commandID = commandID
        self.commandName = commandName
        self.startedAt = startedAt
        self.duration = duration
        self.exitCode = exitCode
        self.stdout = stdout
        self.stderr = stderr
        self.failureMessage = failureMessage
    }

    /// A clean exit (status 0) with no failure message.
    public var succeeded: Bool { failureMessage == nil && exitCode == 0 }

    /// Builds a record from a successful `CommandResult`.
    public static func from(_ result: CommandResult, command: RelayCommand, startedAt: Date) -> ExecutionRecord {
        ExecutionRecord(
            commandID: command.id,
            commandName: command.name,
            startedAt: startedAt,
            duration: result.duration,
            exitCode: result.exitCode,
            stdout: result.stdout,
            stderr: result.stderr
        )
    }

    /// Builds a record for an execution that threw before producing a result.
    public static func failure(_ message: String, command: RelayCommand, startedAt: Date) -> ExecutionRecord {
        ExecutionRecord(
            commandID: command.id,
            commandName: command.name,
            startedAt: startedAt,
            duration: Date().timeIntervalSince(startedAt),
            exitCode: -1,
            stdout: "",
            stderr: "",
            failureMessage: message
        )
    }
}
