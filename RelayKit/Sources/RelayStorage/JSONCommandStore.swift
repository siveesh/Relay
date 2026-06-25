import Foundation
import RelayCore

/// File-backed command store that persists the library as a single JSON document.
///
/// This is the default production store. It lives behind `CommandStoring`, so a future
/// SQLite-backed store can replace it without touching any call site. An `actor` serializes
/// all disk access.
public actor JSONCommandStore: CommandStoring {

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    /// Creates a store writing to `<Application Support>/Relay/commands.json` by default.
    public init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSTemporaryDirectory())
            self.fileURL = base
                .appendingPathComponent("Relay", isDirectory: true)
                .appendingPathComponent("commands.json", isDirectory: false)
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        self.encoder = encoder
        self.decoder = JSONDecoder()
    }

    /// The location this store reads from and writes to.
    public var location: URL { fileURL }

    public func loadCommands() async throws -> [RelayCommand] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode([RelayCommand].self, from: data)
    }

    public func save(_ commands: [RelayCommand]) async throws {
        try ensureDirectoryExists()
        let data = try encoder.encode(commands)
        // Atomic write so a crash mid-save cannot corrupt the library.
        try data.write(to: fileURL, options: [.atomic])
    }

    private func ensureDirectoryExists() throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
}
