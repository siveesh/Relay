import Testing
import Foundation
@testable import RelayCore

@Suite("ShellExecutor")
struct ShellExecutorTests {

    @Test("Captures stdout and a zero exit code")
    func capturesStdout() async throws {
        let executor = ShellExecutor()
        let command = RelayCommand(name: "echo", command: "echo hello", timeoutSeconds: 10)
        let result = try await executor.run(command)

        #expect(result.stdout.trimmingCharacters(in: .whitespacesAndNewlines) == "hello")
        #expect(result.exitCode == 0)
        #expect(result.succeeded)
    }

    @Test("Captures stderr and a non-zero exit code")
    func capturesFailure() async throws {
        let executor = ShellExecutor()
        let command = RelayCommand(name: "fail", command: "echo oops 1>&2; exit 3", timeoutSeconds: 10)
        let result = try await executor.run(command)

        #expect(result.stderr.contains("oops"))
        #expect(result.exitCode == 3)
        #expect(!result.succeeded)
    }

    @Test("Reads large output without deadlocking")
    func largeOutput() async throws {
        let executor = ShellExecutor()
        // ~200KB, far beyond a pipe buffer — would deadlock on a naive read-after-wait.
        let command = RelayCommand(name: "big", command: "yes ABCDEFGH | head -n 25000", timeoutSeconds: 20)
        let result = try await executor.run(command)

        #expect(result.exitCode == 0)
        #expect(result.stdout.count > 100_000)
    }
}
