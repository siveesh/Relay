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
        snapshotIfNeeded()
        let data = try encoder.encode(commands)
        // Atomic write so a crash mid-save cannot corrupt the library.
        try data.write(to: fileURL, options: [.atomic])
    }

    // MARK: - Snapshots

    /// The directory that holds auto-snapshots: `<Application Support>/Relay/Snapshots/`.
    public var snapshotsDirectory: URL {
        fileURL.deletingLastPathComponent().appendingPathComponent("Snapshots", isDirectory: true)
    }

    /// Returns snapshot URLs sorted newest-first.
    public func snapshots() -> [URL] {
        let fm = FileManager.default
        guard let items = try? fm.contentsOfDirectory(
            at: snapshotsDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else { return [] }
        return items
            .filter { $0.pathExtension == "json" }
            .sorted { a, b in
                let dateA = (try? a.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let dateB = (try? b.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return dateA > dateB
            }
    }

    /// Restores a previously saved snapshot, replacing the live library.
    public func restore(from snapshot: URL) throws {
        let data = try Data(contentsOf: snapshot)
        try ensureDirectoryExists()
        try data.write(to: fileURL, options: [.atomic])
    }

    /// Copies the current `commands.json` to the snapshots directory, keeping only the last 10.
    private func snapshotIfNeeded() {
        let fm = FileManager.default
        guard fm.fileExists(atPath: fileURL.path) else { return }
        let dir = snapshotsDirectory
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)

        let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let dest = dir.appendingPathComponent("commands-\(stamp).json")
        try? fm.copyItem(at: fileURL, to: dest)

        // Prune: keep newest 10 only.
        let all = snapshots()
        if all.count > 10 {
            for old in all.dropFirst(10) { try? fm.removeItem(at: old) }
        }
    }

    private func ensureDirectoryExists() throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
}
