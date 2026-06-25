import Foundation
import RelayCore

/// Imports and exports command packs, and merges imported commands into an existing library.
public struct PackTransfer: Sendable {

    public init() {}

    // MARK: Import

    /// Decodes a (lenient) command pack from JSON data into strict `RelayCommand`s, mapping
    /// pack slugs to stable UUIDs.
    public func importCommands(from data: Data) throws -> [RelayCommand] {
        let dto = try JSONDecoder().decode(CommandPackDTO.self, from: data)
        return dto.commands.map { $0.toCommand() }
    }

    /// Merges imported commands into an existing library. Commands with a matching id replace
    /// the existing entry (idempotent re-import); new commands are appended.
    public func merge(_ imported: [RelayCommand], into existing: [RelayCommand]) -> [RelayCommand] {
        var byID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        var order = existing.map(\.id)

        for command in imported {
            if byID[command.id] == nil { order.append(command.id) }
            byID[command.id] = command
        }

        return order.compactMap { byID[$0] }
    }

    // MARK: Export

    /// Encodes commands as a pretty-printed JSON command pack.
    public func exportPack(named name: String, version: String = "1.0", commands: [RelayCommand]) throws -> Data {
        let pack = CommandPack(packName: name, version: version, commands: commands)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(pack)
    }
}
