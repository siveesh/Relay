import Testing
import Foundation
import RelayCore
@testable import RelaySearch

@Suite("FuzzySearchEngine")
struct FuzzySearchEngineTests {

    private let engine = FuzzySearchEngine()
    private let commands = RelayCommand.samples

    @Test("Empty query returns everything, favorites first")
    func emptyQueryPrioritizesFavorites() {
        let results = engine.search("", in: commands)
        #expect(results.count == commands.count)
        #expect(results.first?.favorite == true)
    }

    @Test("Exact name match ranks first")
    func exactMatchRanksFirst() {
        let results = engine.search("Tailscale Status", in: commands)
        #expect(results.first?.name == "Tailscale Status")
    }

    @Test("Alias matches are found")
    func aliasMatch() {
        let results = engine.search("dns flush", in: commands)
        #expect(results.first?.name == "Flush DNS Cache")
    }

    @Test("Subsequence matches but unrelated queries do not")
    func subsequenceAndMiss() {
        #expect(engine.search("gs", in: commands).contains { $0.name == "Git Status" })
        #expect(engine.search("zzzqzzz", in: commands).isEmpty)
    }

    @Test("Prefix scores higher than scattered subsequence")
    func scoringOrder() {
        let prefix = FuzzySearchEngine.score(query: "tai", in: "tailscale")
        let subseq = FuzzySearchEngine.score(query: "tai", in: "the application install")
        #expect(prefix != nil)
        #expect((prefix ?? 0) > (subseq ?? 0))
    }

    @Test("Usage boost surfaces frequently-used commands on empty query")
    func usageBoostsRecents() {
        let frequent = commands.first { !$0.favorite }!   // a non-favorite
        let records = (0..<10).map { _ in
            ExecutionRecord(commandID: frequent.id, commandName: frequent.name,
                            startedAt: Date(), duration: 0.1, exitCode: 0, stdout: "", stderr: "")
        }
        let usage = UsageStats.from(records)
        let results = engine.search("", in: commands, usage: usage)
        // The heavily-used non-favorite should be ahead of unused non-favorites.
        let unusedNonFavorites = commands.filter { !$0.favorite && $0.id != frequent.id }
        let frequentIndex = results.firstIndex { $0.id == frequent.id }!
        for cmd in unusedNonFavorites {
            #expect(frequentIndex < results.firstIndex { $0.id == cmd.id }!)
        }
    }

    @Test("Recency decays: recent beats old")
    func recencyDecay() {
        let usage = UsageStats(
            counts: [:],
            lastUsed: [:],
            referenceDate: Date()
        )
        let now = usage.referenceDate
        let id = UUID()
        let recent = UsageStats(counts: [id: 1], lastUsed: [id: now], referenceDate: now)
        let old = UsageStats(counts: [id: 1], lastUsed: [id: now.addingTimeInterval(-30 * 86_400)], referenceDate: now)
        #expect(recent.boost(for: id) > old.boost(for: id))
    }
}
