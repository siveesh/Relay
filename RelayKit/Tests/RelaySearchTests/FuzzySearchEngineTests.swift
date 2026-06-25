import Testing
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
        // "gs" is an alias and a subsequence of "Git Status".
        #expect(engine.search("gs", in: commands).contains { $0.name == "Git Status" })
        // A query that cannot be a subsequence of anything returns no results.
        #expect(engine.search("zzzqzzz", in: commands).isEmpty)
    }

    @Test("Prefix scores higher than scattered subsequence")
    func scoringOrder() {
        let prefix = FuzzySearchEngine.score(query: "tai", in: "tailscale")
        let subseq = FuzzySearchEngine.score(query: "tai", in: "the application install")
        #expect(prefix != nil)
        #expect((prefix ?? 0) > (subseq ?? 0))
    }
}
