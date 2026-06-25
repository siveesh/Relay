import Foundation
import Observation
import RelayCore

/// Observable, persisted execution-history log.
@MainActor
@Observable
final class HistoryModel {

    private(set) var records: [ExecutionRecord] = []

    private let store: any HistoryStoring

    init(store: any HistoryStoring) {
        self.store = store
    }

    func load() async {
        records = (try? await store.load()) ?? []
    }

    /// Appends a record (most recent last) and persists.
    func append(_ record: ExecutionRecord) {
        records.append(record)
        persist()
    }

    func clear() {
        records.removeAll()
        persist()
    }

    /// Records most-recent first, for display.
    var newestFirst: [ExecutionRecord] {
        records.reversed()
    }

    private func persist() {
        let snapshot = records
        Task { try? await store.save(snapshot) }
    }
}
