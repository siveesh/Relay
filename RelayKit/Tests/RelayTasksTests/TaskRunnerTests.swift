import Testing
import Foundation
import RelayCore
@testable import RelayTasks

@Suite("RelayTasks")
struct TaskRunnerTests {

    @Test("TaskStep kinds are codable")
    func taskStepCodable() throws {
        let step = TaskStep(kind: .delay(seconds: 1.5))
        let data = try JSONEncoder().encode(step)
        let decoded = try JSONDecoder().decode(TaskStep.self, from: data)
        #expect(decoded == step)
    }
}
