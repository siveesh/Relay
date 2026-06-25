import Foundation

/// Per-command usage signals derived from the execution history, used to rank search results.
public struct UsageStats: Sendable, Equatable {

    /// Number of times each command has been run.
    public var counts: [UUID: Int]
    /// The most recent time each command was run.
    public var lastUsed: [UUID: Date]
    /// Reference point for recency decay (defaults to "now").
    public var referenceDate: Date

    public static let empty = UsageStats(counts: [:], lastUsed: [:], referenceDate: .distantPast)

    public init(counts: [UUID: Int], lastUsed: [UUID: Date], referenceDate: Date) {
        self.counts = counts
        self.lastUsed = lastUsed
        self.referenceDate = referenceDate
    }

    /// Builds usage statistics from execution records.
    public static func from(_ records: [ExecutionRecord], now: Date = Date()) -> UsageStats {
        var counts: [UUID: Int] = [:]
        var lastUsed: [UUID: Date] = [:]
        for record in records {
            counts[record.commandID, default: 0] += 1
            if let existing = lastUsed[record.commandID] {
                if record.startedAt > existing { lastUsed[record.commandID] = record.startedAt }
            } else {
                lastUsed[record.commandID] = record.startedAt
            }
        }
        return UsageStats(counts: counts, lastUsed: lastUsed, referenceDate: now)
    }

    /// A bounded ranking bonus combining frequency (log-scaled) and recency (exponential
    /// decay, half-life ≈ 3 days). Returns roughly `0...1`.
    public func boost(for id: UUID) -> Double {
        let count = counts[id] ?? 0
        let frequency = count > 0 ? log2(Double(count) + 1) / 6.0 : 0   // ~0...0.5 for 0..~63 runs

        var recency = 0.0
        if let last = lastUsed[id] {
            let ageDays = max(0, referenceDate.timeIntervalSince(last)) / 86_400
            recency = 0.5 * pow(0.5, ageDays / 3.0)                      // 0.5 now → 0.25 at 3 days
        }
        return min(1.0, frequency + recency)
    }

    /// Commands ordered most-recently-used first (only those with history).
    public func recentIDs() -> [UUID] {
        lastUsed.sorted { $0.value > $1.value }.map(\.key)
    }
}
