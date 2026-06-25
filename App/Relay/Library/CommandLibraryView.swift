import SwiftUI
import UniformTypeIdentifiers
import RelayCore
import RelayCommandPacks
import RelayUI

/// The command management window: browse, search, add, edit, delete, import, and export.
struct CommandLibraryView: View {

    @Bindable var library: CommandLibraryModel

    @State private var search = ""
    @State private var selection: RelayCommand.ID?
    @State private var editing: EditingState?
    @State private var importing = false
    @State private var exporting = false

    var body: some View {
        NavigationSplitView {
            list
        } detail: {
            detail
        }
        .navigationTitle("Command Library")
        .toolbar { toolbar }
        .sheet(item: $editing) { state in
            CommandEditorView(
                command: state.command,
                onSave: { command in
                    if state.command == nil { library.add(command) } else { library.update(command) }
                    selection = command.id
                    editing = nil
                },
                onCancel: { editing = nil }
            )
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            if case let .success(url) = result { importPack(url) }
        }
        .fileExporter(
            isPresented: $exporting,
            document: PackDocument(data: exportData),
            contentType: .json,
            defaultFilename: "Relay Library"
        ) { _ in }
    }

    /// The library encoded as command-pack JSON, produced on the main actor.
    private var exportData: Data {
        (try? PackTransfer().exportPack(named: "Relay Library", commands: library.commands)) ?? Data()
    }

    // MARK: List

    private var filtered: [RelayCommand] {
        let base = library.commands.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        guard !search.isEmpty else { return base }
        return base.filter {
            $0.name.localizedCaseInsensitiveContains(search)
                || $0.category.localizedCaseInsensitiveContains(search)
                || $0.tags.contains { $0.localizedCaseInsensitiveContains(search) }
        }
    }

    private var list: some View {
        List(filtered, selection: $selection) { command in
            HStack(spacing: 10) {
                Image(systemName: command.icon)
                    .foregroundStyle(RelayTheme.accentGradient)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 1) {
                    Text(command.name)
                    Text(command.category).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if command.favorite {
                    Image(systemName: "star.fill").font(.caption2).foregroundStyle(RelayTheme.cyan)
                }
            }
            .tag(command.id)
            .contextMenu {
                Button("Edit") { editing = EditingState(command: command) }
                Button(command.favorite ? "Unfavorite" : "Favorite") { library.toggleFavorite(command) }
                Divider()
                Button("Delete", role: .destructive) { library.delete(command) }
            }
        }
        .searchable(text: $search, placement: .sidebar)
        .frame(minWidth: 260)
    }

    // MARK: Detail

    @ViewBuilder private var detail: some View {
        if let selected = library.commands.first(where: { $0.id == selection }) {
            CommandDetailView(command: selected) {
                editing = EditingState(command: selected)
            }
        } else {
            ContentUnavailableView("No Command Selected", systemImage: "command", description: Text("Select a command to view its details, or add a new one."))
        }
    }

    // MARK: Toolbar

    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        ToolbarItemGroup {
            Button { importing = true } label: { Label("Import", systemImage: "square.and.arrow.down") }
            Button { exporting = true } label: { Label("Export", systemImage: "square.and.arrow.up") }
            Button { editing = EditingState(command: nil) } label: { Label("Add", systemImage: "plus") }
                .keyboardShortcut("n", modifiers: .command)
        }
    }

    private func importPack(_ url: URL) {
        let needsScope = url.startAccessingSecurityScopedResource()
        defer { if needsScope { url.stopAccessingSecurityScopedResource() } }
        try? library.importPack(from: url)
    }
}

/// Identifiable wrapper so a `nil` (new) command can still drive a `.sheet(item:)`.
private struct EditingState: Identifiable {
    let id = UUID()
    let command: RelayCommand?
}

/// Read-only detail pane for a selected command.
private struct CommandDetailView: View {
    let command: RelayCommand
    let onEdit: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: command.icon)
                        .font(.system(size: 28))
                        .foregroundStyle(RelayTheme.accentGradient)
                    VStack(alignment: .leading) {
                        Text(command.name).font(.title2.bold())
                        if !command.details.isEmpty {
                            Text(command.details).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Button("Edit", action: onEdit)
                }

                LabeledRow("Category", command.category)
                LabeledRow("Shell", command.shell)
                LabeledRow("Working dir", command.workingDirectory)
                if !command.tags.isEmpty { LabeledRow("Tags", command.tags.joined(separator: ", ")) }
                if !command.aliases.isEmpty { LabeledRow("Aliases", command.aliases.joined(separator: ", ")) }
                LabeledRow("Timeout", "\(command.timeoutSeconds)s")

                VStack(alignment: .leading, spacing: 4) {
                    Text("Command").font(.caption).foregroundStyle(.secondary)
                    Text(command.command)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                }

                HStack(spacing: 8) {
                    if command.requiresElevation { Badge("Elevation", "lock.fill") }
                    if command.requiresConfirmation { Badge("Confirm", "checkmark.shield") }
                    if command.runInBackground { Badge("Background", "moon") }
                    if command.favorite { Badge("Favorite", "star.fill") }
                }
            }
            .padding(24)
        }
    }
}

private struct LabeledRow: View {
    let label: String
    let value: String
    init(_ label: String, _ value: String) { self.label = label; self.value = value }
    var body: some View {
        HStack(alignment: .top) {
            Text(label).frame(width: 110, alignment: .leading).foregroundStyle(.secondary)
            Text(value).textSelection(.enabled)
            Spacer()
        }
        .font(.callout)
    }
}

private struct Badge: View {
    let text: String
    let icon: String
    init(_ text: String, _ icon: String) { self.text = text; self.icon = icon }
    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption2)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(.quaternary, in: Capsule())
    }
}
