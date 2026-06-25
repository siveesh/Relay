import Foundation

public struct CommandResult: Sendable {
    public let stdout: String
    public let stderr: String
    public let exitCode: Int32
    public let duration: TimeInterval
}

public actor ShellExecutor {
    public init() {}

    public func run(_ command: RelayCommand) async throws -> CommandResult {
        let start = Date()

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/\(command.shell)")
        process.arguments = ["-lc", command.command]

        if !command.workingDirectory.isEmpty {
            let expanded = NSString(string: command.workingDirectory).expandingTildeInPath
            process.currentDirectoryURL = URL(fileURLWithPath: expanded)
        }

        var env = ProcessInfo.processInfo.environment
        command.environment.forEach { env[$0.key] = $0.value }
        process.environment = env

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

        return CommandResult(
            stdout: String(data: stdoutData, encoding: .utf8) ?? "",
            stderr: String(data: stderrData, encoding: .utf8) ?? "",
            exitCode: process.terminationStatus,
            duration: Date().timeIntervalSince(start)
        )
    }
}
