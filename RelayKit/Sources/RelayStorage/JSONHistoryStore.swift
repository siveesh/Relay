import Foundation
import RelayCore

/// File-backed execution-history store. Keeps the most recent `limit` records.
public actor JSONHistoryStore: HistoryStoring {

    private let fileURL: URL
    private let limit: Int
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(fileURL: URL? = nil, limit: Int = 500) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSTemporaryDirectory())
            self.fileURL = base
                .appendingPathComponent("Relay", isDirectory: true)
                .appendingPathComponent("history.json", isDirectory: false)
        }
        self.limit = limit

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public func load() async throws -> [ExecutionRecord] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode([ExecutionRecord].self, from: data)
    }

    public func save(_ records: [ExecutionRecord]) async throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let trimmed = Array(records.suffix(limit))
        let data = try encoder.encode(trimmed)
        try data.write(to: fileURL, options: [.atomic])
    }
}
