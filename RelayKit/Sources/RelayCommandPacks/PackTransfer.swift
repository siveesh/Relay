import Foundation
import RelayCore

/// Imports and exports `CommandPack` JSON documents.
///
/// > Milestone note: the full import flow (slug→UUID migration, de-duplication, merge into the
/// > store) lands in Milestone 2. These primitives encode/decode packs and are ready now.
public struct PackTransfer: Sendable {

    public init() {}

    /// Decodes a command pack from JSON data.
    public func decodePack(from data: Data) throws -> CommandPack {
        try JSONDecoder().decode(CommandPack.self, from: data)
    }

    /// Encodes a command pack to pretty-printed JSON.
    public func encodePack(_ pack: CommandPack) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(pack)
    }
}
