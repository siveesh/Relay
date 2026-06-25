import Testing
import Foundation
import RelayCore
@testable import RelaySearch

@Suite("Search performance")
struct SearchPerformanceTests {

    /// A large synthetic library to validate the search latency budget.
    private func makeLibrary(_ count: Int) -> [RelayCommand] {
        let categories = ["AI", "Development", "Network", "System", "Media"]
        return (0..<count).map { i in
            RelayCommand(
                name: "Command \(i) \(["build", "deploy", "status", "flush", "restart"][i % 5])",
                category: categories[i % categories.count],
                tags: ["tag\(i % 20)", "common"],
                aliases: ["c\(i)"],
                command: "echo \(i)"
            )
        }
    }

    @Test("Search over 2,000 commands stays within the latency budget")
    func searchLatency() {
        let engine = FuzzySearchEngine()
        let library = makeLibrary(2_000)
        let usage = UsageStats.empty

        // Warm up, then measure.
        _ = engine.search("stat", in: library, usage: usage)

        let start = Date()
        let results = engine.search("depl", in: library, usage: usage)
        let elapsed = Date().timeIntervalSince(start)

        #expect(!results.isEmpty)
        // Target is < 20 ms; assert a generous ceiling to stay non-flaky across machines.
        #expect(elapsed < 0.1, "search took \(elapsed * 1000) ms")
    }
}
