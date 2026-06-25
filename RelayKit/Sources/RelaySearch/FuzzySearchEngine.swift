import Foundation
import RelayCore

/// Fast in-memory fuzzy search over the command library.
///
/// Matching is subsequence-based (every query character must appear in order). Scoring
/// rewards exact/prefix matches, contiguous runs, word-boundary hits, and matches against
/// the name over tags/aliases. Favorites get a small boost.
///
/// > Milestone note: frequency/recency signals are layered in at Milestone 4 once history
/// > exists. The protocol and ranking shape are stable now.
public struct FuzzySearchEngine: CommandSearching {

    public init() {}

    public func search(_ query: String, in commands: [RelayCommand]) -> [RelayCommand] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else {
            // No query: favorites first, then stable order.
            return commands.sorted { ($0.favorite ? 1 : 0) > ($1.favorite ? 1 : 0) }
        }

        let scored: [(command: RelayCommand, score: Double)] = commands.compactMap { command in
            guard let score = bestScore(for: command, query: trimmed) else { return nil }
            return (command, score)
        }

        return scored
            .sorted { $0.score > $1.score }
            .map(\.command)
    }

    /// The best score across all searchable fields of a command, or `nil` if nothing matches.
    private func bestScore(for command: RelayCommand, query: String) -> Double? {
        var best: Double?

        func consider(_ candidate: String, weight: Double) {
            guard let raw = Self.score(query: query, in: candidate.lowercased()) else { return }
            let weighted = raw * weight
            if best == nil || weighted > best! { best = weighted }
        }

        consider(command.name, weight: 1.0)
        for alias in command.aliases { consider(alias, weight: 0.95) }
        consider(command.category, weight: 0.7)
        for tag in command.tags { consider(tag, weight: 0.6) }
        consider(command.details, weight: 0.4)

        guard let baseScore = best else { return nil }
        return command.favorite ? baseScore + 0.25 : baseScore
    }

    /// Scores a single candidate string against the query. Returns `nil` when the query is
    /// not a subsequence of the candidate. Higher is better; normalized roughly to `0...2`.
    static func score(query: String, in candidate: String) -> Double? {
        if candidate == query { return 2.0 }                 // exact
        if candidate.hasPrefix(query) { return 1.5 }         // prefix
        if candidate.contains(query) { return 1.0 }          // contiguous substring

        // Subsequence match with a bonus for contiguous runs.
        let queryChars = Array(query)
        let candidateChars = Array(candidate)
        var qi = 0
        var run = 0
        var bonus = 0.0
        for ch in candidateChars {
            guard qi < queryChars.count else { break }
            if ch == queryChars[qi] {
                qi += 1
                run += 1
                bonus += Double(run) * 0.02   // longer contiguous runs score higher
            } else {
                run = 0
            }
        }
        guard qi == queryChars.count else { return nil }

        // Base 0.5 for a subsequence hit, plus run bonus, minus a small length penalty so
        // tighter matches rank above sprawling ones.
        let lengthPenalty = Double(candidateChars.count - queryChars.count) * 0.005
        return max(0.1, 0.5 + bonus - lengthPenalty)
    }
}
