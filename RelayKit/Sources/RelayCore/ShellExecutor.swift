import Foundation

/// Executes commands via `Process` without opening Terminal.
///
/// An `actor` so concurrent executions are serialized at the API boundary and shared state
/// is race-free. The implementation reads `stdout`/`stderr` concurrently (avoiding the
/// classic pipe-buffer deadlock) and enforces the command's timeout.
///
/// > Milestone note: real output streaming, progress reporting, and full cooperative
/// > cancellation are completed in Milestone 3. This M1 version is correct and deadlock-free.
public actor ShellExecutor: CommandExecuting {

    public init() {}

    public func run(_ command: RelayCommand) async throws -> CommandResult {
        let start = Date()

        let shellPath = "/bin/\(command.shell)"
        guard FileManager.default.isExecutableFile(atPath: shellPath) else {
            throw ExecutionError.shellNotFound(command.shell)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: shellPath)
        process.arguments = ["-lc", command.command]

        let trimmedWorkingDir = command.workingDirectory.trimmingCharacters(in: .whitespaces)
        if !trimmedWorkingDir.isEmpty {
            let expanded = NSString(string: trimmedWorkingDir).expandingTildeInPath
            process.currentDirectoryURL = URL(fileURLWithPath: expanded)
        }

        var environment = ProcessInfo.processInfo.environment
        for (key, value) in command.environment { environment[key] = value }
        process.environment = environment

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
        } catch {
            throw ExecutionError.launchFailed(error.localizedDescription)
        }

        // Enforce the timeout by terminating the process if it overruns. The task inherits
        // this actor's isolation, so touching `process` here is race-free.
        let timeoutTask: Task<Void, Never>?
        if command.timeoutSeconds > 0 {
            let seconds = command.timeoutSeconds
            timeoutTask = Task { [process] in
                try? await Task.sleep(for: .seconds(seconds))
                if process.isRunning { process.terminate() }
            }
        } else {
            timeoutTask = nil
        }

        // Read both pipes off the actor concurrently so a large stream on one cannot block
        // the other (the pipe-buffer deadlock).
        async let stdoutData = Self.readToEnd(stdoutPipe.fileHandleForReading)
        async let stderrData = Self.readToEnd(stderrPipe.fileHandleForReading)

        await Self.waitForExit(process)
        timeoutTask?.cancel()

        let outText = String(decoding: await stdoutData, as: UTF8.self)
        let errText = String(decoding: await stderrData, as: UTF8.self)

        return CommandResult(
            stdout: outText,
            stderr: errText,
            exitCode: process.terminationStatus,
            duration: Date().timeIntervalSince(start)
        )
    }

    /// Reads a file handle to EOF off the cooperative pool.
    private static func readToEnd(_ handle: FileHandle) async -> Data {
        await Task.detached(priority: .userInitiated) {
            (try? handle.readToEnd()) ?? Data()
        }.value
    }

    /// Suspends until the process exits, using its termination handler instead of a blocking wait.
    private static func waitForExit(_ process: Process) async {
        // One-shot guard: the termination handler runs on an arbitrary thread and could race
        // with the already-exited check below; resuming a continuation twice is a crash.
        final class ResumeOnce: @unchecked Sendable {
            private let lock = NSLock()
            private var done = false
            func fire(_ continuation: CheckedContinuation<Void, Never>) {
                lock.lock(); defer { lock.unlock() }
                guard !done else { return }
                done = true
                continuation.resume()
            }
        }

        let once = ResumeOnce()
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            process.terminationHandler = { _ in once.fire(continuation) }
            // Cover the case where the process exited before the handler was attached.
            if !process.isRunning { once.fire(continuation) }
        }
    }
}
