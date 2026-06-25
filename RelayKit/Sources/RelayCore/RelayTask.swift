import Foundation

/// A multi-step workflow. The task runner (RelayTasks module) executes the steps in order,
/// honouring `stopOnFailure`, retries, and conditional branches.
///
/// > Milestone note: the model is defined now so the architecture and persistence layer are
/// > stable; the executing engine lands in Milestone 5.
public struct RelayTask: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var details: String
    public var icon: String
    public var steps: [TaskStep]
    public var stopOnFailure: Bool
    public var favorite: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        details: String = "",
        icon: String = "list.bullet.rectangle",
        steps: [TaskStep] = [],
        stopOnFailure: Bool = true,
        favorite: Bool = false
    ) {
        self.id = id
        self.name = name
        self.details = details
        self.icon = icon
        self.steps = steps
        self.stopOnFailure = stopOnFailure
        self.favorite = favorite
    }
}

/// A single step within a `RelayTask`.
public struct TaskStep: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var kind: Kind
    public var continueOnError: Bool
    public var retryCount: Int

    /// The kinds of action a workflow step can perform. Designed to be extended without
    /// breaking existing data (new cases append; decoding tolerates unknowns in M5).
    public enum Kind: Codable, Hashable, Sendable {
        case shell(command: String, shell: String)
        case launchApp(bundleIdentifier: String)
        case quitApp(bundleIdentifier: String)
        case delay(seconds: Double)
        case waitUntil(condition: String)
        case httpHealthCheck(url: String, expectedStatus: Int)
        case appleScript(source: String)
        case javaScriptForAutomation(source: String)
        case notify(title: String, body: String)
    }

    public init(
        id: UUID = UUID(),
        kind: Kind,
        continueOnError: Bool = false,
        retryCount: Int = 0
    ) {
        self.id = id
        self.kind = kind
        self.continueOnError = continueOnError
        self.retryCount = retryCount
    }
}
