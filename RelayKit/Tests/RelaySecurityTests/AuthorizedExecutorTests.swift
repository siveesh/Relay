import Testing
import Foundation
import RelayCore
@testable import RelaySecurity

@Suite("AuthorizedExecutor")
struct AuthorizedExecutorTests {

    /// Records the command it was asked to run instead of executing it.
    actor SpyExecutor: CommandExecuting {
        private(set) var lastCommand: RelayCommand?
        func run(_ command: RelayCommand) async throws -> CommandResult {
            lastCommand = command
            return CommandResult(stdout: "", stderr: "", exitCode: 0, duration: 0)
        }
        func recorded() -> RelayCommand? { lastCommand }
    }

    @Test("Non-elevated commands pass through unchanged")
    func passthrough() async throws {
        let spy = SpyExecutor()
        let executor = AuthorizedExecutor(base: spy)
        let command = RelayCommand(name: "ls", command: "ls -la")

        _ = try await executor.run(command)
        let recorded = await spy.recorded()
        #expect(recorded?.command == "ls -la")
    }

    @Test("Elevated commands are wrapped in osascript admin auth, sudo stripped")
    func elevationWrapping() async throws {
        let spy = SpyExecutor()
        let executor = AuthorizedExecutor(base: spy)
        let command = RelayCommand(name: "dns", command: "sudo dscacheutil -flushcache", requiresElevation: true)

        _ = try await executor.run(command)
        let recorded = await spy.recorded()

        #expect(recorded?.command.contains("osascript") == true)
        #expect(recorded?.command.contains("with administrator privileges") == true)
        #expect(recorded?.command.contains("dscacheutil -flushcache") == true)
        #expect(recorded?.command.contains("sudo") == false)
        #expect(recorded?.requiresElevation == false)   // does not recurse
    }

    @Test("Shell single-quoting escapes embedded quotes")
    func shellQuoting() {
        #expect(AuthorizedExecutor.shellSingleQuoted("a'b") == "'a'\\''b'")
    }
}
