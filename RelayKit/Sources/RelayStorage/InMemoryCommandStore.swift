import Foundation
import RelayCore

/// A volatile command store backed by an in-memory array. Used for M1 (sample data) and as a
/// test double. Thread-safe via actor isolation.
public actor InMemoryCommandStore: CommandStoring {
    private var commands: [RelayCommand]

    public init(seed: [RelayCommand] = []) {
        self.commands = seed
    }

    public func loadCommands() async throws -> [RelayCommand] {
        commands
    }

    public func save(_ commands: [RelayCommand]) async throws {
        self.commands = commands
    }
}
