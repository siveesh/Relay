import Foundation
import Observation
import RelayCore

/// View model for the command palette. Owns the query, the current result list, and the
/// keyboard selection. Pure presentation state — execution and persistence are injected.
@MainActor
@Observable
public final class CommandPaletteModel {

    /// The user's search text. Updating it recomputes `results`.
    public var query: String = "" {
        didSet { recompute() }
    }

    /// The currently filtered, ranked results.
    public private(set) var results: [RelayCommand] = []

    /// Index of the highlighted result within `results`.
    public private(set) var selectionIndex: Int = 0

    /// True while the query is empty — the palette is showing recents/favorites, not results.
    public private(set) var isShowingSuggestions: Bool = true

    private let commands: [RelayCommand]
    private let search: any CommandSearching
    private let usage: UsageStats

    public init(commands: [RelayCommand], search: any CommandSearching, usage: UsageStats = .empty) {
        self.commands = commands
        self.search = search
        self.usage = usage
        recompute()
    }

    /// The command the user would run by pressing Return, if any.
    public var selectedCommand: RelayCommand? {
        guard results.indices.contains(selectionIndex) else { return nil }
        return results[selectionIndex]
    }

    /// Moves the highlight down one row, clamped to the list.
    public func selectNext() {
        guard !results.isEmpty else { return }
        selectionIndex = min(selectionIndex + 1, results.count - 1)
    }

    /// Moves the highlight up one row, clamped to the list.
    public func selectPrevious() {
        guard !results.isEmpty else { return }
        selectionIndex = max(selectionIndex - 1, 0)
    }

    /// Highlights a specific result (e.g. on hover/click).
    public func select(_ command: RelayCommand) {
        if let index = results.firstIndex(where: { $0.id == command.id }) {
            selectionIndex = index
        }
    }

    /// Resets the palette to its initial state for the next time it is summoned.
    public func reset() {
        query = ""
    }

    private func recompute() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        isShowingSuggestions = trimmed.isEmpty
        results = search.search(query, in: commands, usage: usage)
        selectionIndex = 0
    }
}
