import Testing
import Foundation
import RelayCore
@testable import RelayCommandPacks

@Suite("PackTransfer")
struct PackTransferTests {

    private let starterPack = """
    {
      "packName": "Relay Starter Pack",
      "version": "0.1",
      "commands": [
        {
          "id": "start-lm-studio",
          "name": "Start LM Studio",
          "description": "Launch LM Studio.",
          "category": "AI",
          "icon": "brain",
          "tags": ["ai", "llm"],
          "aliases": ["lm"],
          "shell": "zsh",
          "command": "open -a 'LM Studio'",
          "favorite": true
        },
        {
          "id": "flush-dns",
          "name": "Flush DNS Cache",
          "command": "sudo dscacheutil -flushcache",
          "requiresElevation": true
        }
      ]
    }
    """.data(using: .utf8)!

    @Test("Imports slug-keyed packs into strict commands")
    func importsStarterPack() throws {
        let commands = try PackTransfer().importCommands(from: starterPack)
        #expect(commands.count == 2)
        #expect(commands[0].name == "Start LM Studio")
        #expect(commands[0].favorite)
        #expect(commands[1].requiresElevation)
        // Missing fields fall back to sensible defaults.
        #expect(commands[1].shell == "zsh")
        #expect(commands[1].captureOutput)
    }

    @Test("Slug → UUID mapping is stable across imports")
    func slugMappingIsDeterministic() throws {
        let first = try PackTransfer().importCommands(from: starterPack)
        let second = try PackTransfer().importCommands(from: starterPack)
        #expect(first.map(\.id) == second.map(\.id))
    }

    @Test("Re-importing merges in place instead of duplicating")
    func mergeIsIdempotent() throws {
        let transfer = PackTransfer()
        let imported = try transfer.importCommands(from: starterPack)

        let once = transfer.merge(imported, into: [])
        let twice = transfer.merge(imported, into: once)

        #expect(once.count == 2)
        #expect(twice.count == 2)
    }

    @Test("Export round-trips through import")
    func exportRoundTrip() throws {
        let transfer = PackTransfer()
        let data = try transfer.exportPack(named: "Mine", commands: RelayCommand.samples)
        let reimported = try transfer.importCommands(from: data)
        #expect(reimported.count == RelayCommand.samples.count)
    }
}
