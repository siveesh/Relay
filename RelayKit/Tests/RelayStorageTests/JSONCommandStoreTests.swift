import Testing
import Foundation
import RelayCore
@testable import RelayStorage

@Suite("JSONCommandStore")
struct JSONCommandStoreTests {

    @Test("Saving then loading returns the same commands")
    func saveLoadRoundTrip() async throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("relay-tests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("commands.json")
        defer { try? FileManager.default.removeItem(at: tempURL.deletingLastPathComponent()) }

        let store = JSONCommandStore(fileURL: tempURL)
        let commands = RelayCommand.samples

        try await store.save(commands)
        let loaded = try await store.loadCommands()

        #expect(loaded == commands)
    }

    @Test("Loading from a missing file returns an empty library")
    func loadMissingFile() async throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("relay-missing-\(UUID().uuidString).json")
        let store = JSONCommandStore(fileURL: tempURL)

        let loaded = try await store.loadCommands()
        #expect(loaded.isEmpty)
    }

    @Test("InMemoryCommandStore persists within its lifetime")
    func inMemoryStore() async throws {
        let store = InMemoryCommandStore(seed: RelayCommand.samples)
        #expect(try await store.loadCommands().count == RelayCommand.samples.count)

        try await store.save([])
        #expect(try await store.loadCommands().isEmpty)
    }
}
