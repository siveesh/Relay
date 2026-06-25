import Foundation
import RelayCore

/// File-backed store for the workflow/task library (`<Application Support>/Relay/tasks.json`).
public actor JSONTaskStore: TaskStoring {

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSTemporaryDirectory())
            self.fileURL = base
                .appendingPathComponent("Relay", isDirectory: true)
                .appendingPathComponent("tasks.json", isDirectory: false)
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        self.encoder = encoder
        self.decoder = JSONDecoder()
    }

    public func loadTasks() async throws -> [RelayTask] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode([RelayTask].self, from: data)
    }

    public func save(_ tasks: [RelayTask]) async throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try encoder.encode(tasks)
        try data.write(to: fileURL, options: [.atomic])
    }
}
