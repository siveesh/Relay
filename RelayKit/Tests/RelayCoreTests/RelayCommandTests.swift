import Testing
import Foundation
@testable import RelayCore

@Suite("RelayCommand model")
struct RelayCommandTests {

    @Test("Codable round-trips losslessly")
    func codableRoundTrip() throws {
        let original = RelayCommand(
            name: "Flush DNS Cache",
            details: "Flush macOS DNS cache.",
            category: "System",
            icon: "globe",
            tags: ["dns", "network"],
            aliases: ["dns flush"],
            command: "sudo dscacheutil -flushcache",
            requiresConfirmation: true,
            requiresElevation: true,
            keyboardShortcut: "⌘⇧D",
            favorite: true
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RelayCommand.self, from: data)

        #expect(decoded == original)
    }

    @Test("`description` is the on-disk key for the details field")
    func descriptionCodingKey() throws {
        let command = RelayCommand(name: "Test", details: "hello", command: "echo hi")
        let data = try JSONEncoder().encode(command)
        let json = String(decoding: data, as: UTF8.self)

        #expect(json.contains("\"description\""))
        #expect(!json.contains("\"details\""))
    }

    @Test("Sample library is non-empty and well-formed")
    func samplesAreValid() {
        #expect(!RelayCommand.samples.isEmpty)
        for command in RelayCommand.samples {
            #expect(!command.name.isEmpty)
            #expect(!command.command.isEmpty)
        }
    }
}
