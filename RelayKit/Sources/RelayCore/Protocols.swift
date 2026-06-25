import Foundation

// MARK: - Execution

/// Anything that can run a `RelayCommand` and return its result.
///
/// The concrete `ShellExecutor` is the default implementation. Future remote/SSH execution
/// can conform to the same protocol so call sites do not change.
public protocol CommandExecuting: Sendable {
    func run(_ command: RelayCommand) async throws -> CommandResult
}

// MARK: - Persistence

/// Storage abstraction for the command library. JSON-backed today; SQLite-backed later.
public protocol CommandStoring: Sendable {
    func loadCommands() async throws -> [RelayCommand]
    func save(_ commands: [RelayCommand]) async throws
}

// MARK: - History

/// Storage abstraction for the execution history log.
public protocol HistoryStoring: Sendable {
    func load() async throws -> [ExecutionRecord]
    func save(_ records: [ExecutionRecord]) async throws
}

// MARK: - Search

/// Search abstraction over the command library. Pure and synchronous so it can run inline
/// on the main actor within the search latency budget.
public protocol CommandSearching: Sendable {
    func search(_ query: String, in commands: [RelayCommand]) -> [RelayCommand]
}

// MARK: - Variables

/// Expands Relay variables (e.g. `$Desktop`, `$Clipboard`, `$Date`) inside command text,
/// working directories, and environment values. Implemented in a later milestone.
public protocol VariableResolving: Sendable {
    func resolve(_ input: String) async -> String
}

// MARK: - Extension points (defined now, implemented later)

/// Future AI assistance. Implementations must only *suggest* commands; generated commands
/// are never executed without explicit user approval.
public protocol CommandSuggesting: Sendable {
    func suggestions(for prompt: String) async throws -> [RelayCommand]
}
