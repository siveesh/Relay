import Foundation

/// Executes commands via `Process` without opening Terminal.
///
/// An `actor` so concurrent executions are serialized at the API boundary and shared state
/// is race-free. The implementation reads `stdout`/`stderr` concurrently (avoiding the
/// classic pipe-buffer deadlock), enforces the command's timeout, and supports cooperative
/// cancellation: cancelling the awaiting `Task` terminates the process and throws
/// `ExecutionError.cancelled`. When `captureOutput` is `false`, output is discarded to
/// `/dev/null` rather than read into memory.
public actor ShellExecutor: CommandExecuting {

    public init() {}

    /// Holds a `Process` so it can be referenced from the (Sendable) cancellation handler.
    /// `Process.terminate()` is safe to call from any thread.
    private final class ProcessBox: @unchecked Sendable {
        let process: Process
        init(_ process: Process) { self.process = process }
    }

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

        // Honor captureOutput: read pipes only when capturing, else discard to /dev/null.
        let stdoutPipe = command.captureOutput ? Pipe() : nil
        let stderrPipe = command.captureOutput ? Pipe() : nil
        process.standardOutput = stdoutPipe ?? FileHandle.nullDevice
        process.standardError = stderrPipe ?? FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            throw ExecutionError.launchFailed(error.localizedDescription)
        }

        let box = ProcessBox(process)

        return try await withTaskCancellationHandler {
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
            async let stdoutData = Self.readToEnd(stdoutPipe?.fileHandleForReading)
            async let stderrData = Self.readToEnd(stderrPipe?.fileHandleForReading)

            await Self.waitForExit(process)
            timeoutTask?.cancel()

            if Task.isCancelled { throw ExecutionError.cancelled }

            let outText = String(decoding: await stdoutData, as: UTF8.self)
            let errText = String(decoding: await stderrData, as: UTF8.self)

            return CommandResult(
                stdout: outText,
                stderr: errText,
                exitCode: process.terminationStatus,
                duration: Date().timeIntervalSince(start)
            )
        } onCancel: {
            box.process.terminate()
        }
    }

    /// Reads a file handle to EOF off the cooperative pool. `nil` (output not captured) → empty.
    private static func readToEnd(_ handle: FileHandle?) async -> Data {
        guard let handle else { return Data() }
        return await Task.detached(priority: .userInitiated) {
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
