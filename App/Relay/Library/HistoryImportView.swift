import SwiftUI
import RelayCore
import RelayStorage

/// Parses ~/.zsh_history and ~/.bash_history and lets the user select commands to import
/// as new Relay library entries.
struct HistoryImportView: View {

    let environment: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    @State private var allEntries: [HistoryEntry] = []
    @State private var selected: Set<UUID> = []
    @State private var filterText = ""
    @State private var importing = false
    @State private var importedCount = 0

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(.secondary)
                Text("Import from Shell History")
                    .font(.headline)
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider()

            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(.tertiary)
                TextField("Filter commands…", text: $filterText)
                    .textFieldStyle(.plain)
                if !filterText.isEmpty {
                    Button { filterText = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.quinary)

            Divider()

            // Entry list
            if allEntries.isEmpty {
                ContentUnavailableView(
                    "No Shell History Found",
                    systemImage: "terminal",
                    description: Text("~/.zsh_history and ~/.bash_history are empty or unavailable.")
                )
                .frame(maxHeight: .infinity)
            } else {
                List(filteredEntries, selection: $selected) { entry in
                    HStack(spacing: 10) {
                        Toggle(isOn: Binding(
                            get: { selected.contains(entry.id) },
                            set: { if $0 { selected.insert(entry.id) } else { selected.remove(entry.id) } }
                        )) { EmptyView() }
                        .toggleStyle(.checkbox)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.command)
                                .font(.system(.body, design: .monospaced))
                                .lineLimit(2)
                            Text(entry.source)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selected.contains(entry.id) { selected.remove(entry.id) }
                        else { selected.insert(entry.id) }
                    }
                }
                .listStyle(.plain)
            }

            Divider()

            // Footer
            HStack {
                Button("Select All") {
                    selected = Set(filteredEntries.map(\.id))
                }
                .disabled(filteredEntries.isEmpty)
                Button("Deselect All") { selected.removeAll() }
                    .disabled(selected.isEmpty)

                Spacer()

                if importedCount > 0 {
                    Text("\(importedCount) commands imported")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button("Import \(selected.isEmpty ? "" : "(\(selected.count))")") {
                    Task { await importSelected() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selected.isEmpty || importing)
            }
            .padding(16)
        }
        .frame(width: 680, height: 520)
        .task { allEntries = await ShellHistoryParser.parse() }
    }

    private var filteredEntries: [HistoryEntry] {
        guard !filterText.isEmpty else { return allEntries }
        let lower = filterText.lowercased()
        return allEntries.filter { $0.command.lowercased().contains(lower) }
    }

    private func importSelected() async {
        importing = true
        let toImport = allEntries.filter { selected.contains($0.id) }
        var commands = (try? await environment.commandStore.loadCommands()) ?? []
        let existing = Set(commands.map(\.command))
        var added = 0
        for entry in toImport {
            guard !existing.contains(entry.command) else { continue }
            let cmd = RelayCommand(
                name: String(entry.command.prefix(60)),
                details: "Imported from \(entry.source)",
                category: "Imported",
                icon: "terminal",
                tags: ["imported", "shell"],
                command: entry.command
            )
            commands.append(cmd)
            added += 1
        }
        try? await environment.commandStore.save(commands)
        await environment.library.load()
        importing = false
        importedCount = added
        selected.removeAll()
        // Remove imported entries from the displayed list.
        let imported = Set(toImport.map(\.id))
        allEntries.removeAll { imported.contains($0.id) }
    }
}

// MARK: - Data model

struct HistoryEntry: Identifiable, Sendable {
    let id: UUID
    let command: String
    let source: String
}

// MARK: - Parser

enum ShellHistoryParser {

    /// Reads both zsh and bash history files, returns unique non-trivial commands.
    static func parse() async -> [HistoryEntry] {
        let home = NSHomeDirectory()
        var seen = Set<String>()
        var results: [HistoryEntry] = []

        let files: [(path: String, parser: (String) -> [String])] = [
            ("\(home)/.zsh_history", parseZshHistory),
            ("\(home)/.bash_history", parseBashHistory),
        ]

        for file in files {
            let sourceName = URL(fileURLWithPath: file.path).lastPathComponent
            guard let text = try? String(contentsOfFile: file.path, encoding: .utf8) else { continue }
            let commands = file.parser(text)
            for cmd in commands {
                let trimmed = cmd.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty, trimmed.count > 3, !seen.contains(trimmed) else { continue }
                seen.insert(trimmed)
                results.append(HistoryEntry(id: UUID(), command: trimmed, source: sourceName))
            }
        }
        return results
    }

    private static func parseZshHistory(_ text: String) -> [String] {
        text.components(separatedBy: "\n").compactMap { line -> String? in
            // Extended format: `: timestamp:elapsed;command`
            if line.hasPrefix(": "), let semi = line.firstIndex(of: ";") {
                return String(line[line.index(after: semi)...])
            }
            return line.isEmpty ? nil : line
        }
    }

    private static func parseBashHistory(_ text: String) -> [String] {
        text.components(separatedBy: "\n").filter { !$0.isEmpty && !$0.hasPrefix("#") }
    }
}
