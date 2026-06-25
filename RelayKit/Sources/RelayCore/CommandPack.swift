import Foundation

/// A portable bundle of commands (and, later, tasks) that can be imported or exported as JSON.
public struct CommandPack: Codable, Hashable, Sendable {
    public var packName: String
    public var version: String
    public var commands: [RelayCommand]

    public init(packName: String, version: String, commands: [RelayCommand]) {
        self.packName = packName
        self.version = version
        self.commands = commands
    }
}
