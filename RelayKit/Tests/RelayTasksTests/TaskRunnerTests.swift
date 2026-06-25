import Testing
import Foundation
import RelayCore
import RelayNotifications
@testable import RelayTasks

@Suite("RelayTasks")
struct TaskRunnerTests {

    // A no-op notification poster for tests.
    struct SilentNotifications: NotificationPosting {
        func requestAuthorization() async {}
        func post(_ notification: RelayNotification) async {}
    }

    private func makeRunner() -> TaskRunner {
        TaskRunner(
            executor: ShellExecutor(),
            notifications: SilentNotifications(),
            resolver: VariableResolver()
        )
    }

    @Test("TaskStep kinds are codable")
    func taskStepCodable() throws {
        let step = TaskStep(kind: .delay(seconds: 1.5))
        let data = try JSONEncoder().encode(step)
        let decoded = try JSONDecoder().decode(TaskStep.self, from: data)
        #expect(decoded == step)
    }

    @Test("Runs a multi-step shell workflow to success")
    func runsShellSteps() async {
        let task = RelayTask(name: "build", steps: [
            TaskStep(kind: .shell(command: "echo one", shell: "zsh")),
            TaskStep(kind: .delay(seconds: 0.01)),
            TaskStep(kind: .shell(command: "echo two", shell: "zsh")),
        ])
        let result = await makeRunner().run(task)
        #expect(result.success)
        #expect(result.outcomes.count == 3)
        #expect(result.outcomes.allSatisfy { $0.success })
    }

    @Test("Stops on failure by default")
    func stopsOnFailure() async {
        let task = RelayTask(name: "fail", steps: [
            TaskStep(kind: .shell(command: "exit 1", shell: "zsh")),
            TaskStep(kind: .shell(command: "echo never", shell: "zsh")),
        ])
        let result = await makeRunner().run(task)
        #expect(!result.success)
        #expect(result.outcomes.count == 1)   // second step not reached
    }

    @Test("continueOnError lets the workflow proceed")
    func continuesOnError() async {
        let task = RelayTask(name: "resilient", steps: [
            TaskStep(kind: .shell(command: "exit 1", shell: "zsh"), continueOnError: true),
            TaskStep(kind: .shell(command: "echo reached", shell: "zsh")),
        ])
        let result = await makeRunner().run(task)
        #expect(!result.success)              // overall failed
        #expect(result.outcomes.count == 2)   // but second step ran
        #expect(result.outcomes[1].success)
    }

    @Test("Retries a failing step the configured number of times")
    func retries() async {
        // A step that always fails with 2 retries → 3 attempts, still fails.
        let task = RelayTask(name: "retry", steps: [
            TaskStep(kind: .shell(command: "exit 7", shell: "zsh"), retryCount: 2),
        ])
        let result = await makeRunner().run(task)
        #expect(!result.success)
        #expect(result.outcomes.first?.message.contains("Exit 7") == true)
    }
}
