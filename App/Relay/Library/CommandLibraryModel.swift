import Foundation
import Observation
import RelayCore
import RelayCommandPacks

/// The single source of truth for the command library: an observable, persisted collection of
/// commands. All mutations write through to the injected store.
@MainActor
@Observable
final class CommandLibraryModel {

    private(set) var commands: [RelayCommand] = []

    private let store: any CommandStoring
    private let packTransfer = PackTransfer()

    init(store: any CommandStoring) {
        self.store = store
    }

    /// Loads the library from disk, seeding the sample commands on first run.
    func load() async {
        do {
            var loaded = try await store.loadCommands()
            if loaded.isEmpty {
                loaded = RelayCommand.samples
                try? await store.save(loaded)
            }
            commands = loaded
        } catch {
            // A corrupt or unreadable store should not leave the user with nothing.
            commands = RelayCommand.samples
        }
    }

    // MARK: Mutations

    func add(_ command: RelayCommand) {
        commands.append(command)
        persist()
    }

    func update(_ command: RelayCommand) {
        guard let index = commands.firstIndex(where: { $0.id == command.id }) else { return }
        commands[index] = command
        persist()
    }

    func delete(_ command: RelayCommand) {
        commands.removeAll { $0.id == command.id }
        persist()
    }

    func toggleFavorite(_ command: RelayCommand) {
        guard let index = commands.firstIndex(where: { $0.id == command.id }) else { return }
        commands[index].favorite.toggle()
        persist()
    }

    // MARK: Import / export

    /// Imports a command pack from a JSON file, merging idempotently into the library.
    func importPack(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let imported = try packTransfer.importCommands(from: data)
        commands = packTransfer.merge(imported, into: commands)
        persist()
    }

    /// Exports the whole library as a command pack JSON file.
    func exportPack(to url: URL, named name: String = "Relay Library") throws {
        let data = try packTransfer.exportPack(named: name, commands: commands)
        try data.write(to: url, options: [.atomic])
    }

    // MARK: Persistence

    private func persist() {
        let snapshot = commands
        Task { try? await store.save(snapshot) }
    }
}
