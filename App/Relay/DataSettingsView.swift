import SwiftUI
import RelayCore
import RelayStorage
import UniformTypeIdentifiers

/// The "Data" tab in Settings: Backup, Restore, Versioning, iCloud info.
struct DataSettingsView: View {

    let environment: AppEnvironment

    @State private var snapshots: [URL] = []
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var exportPayload: BackupBundle?
    @State private var statusMessage: String?

    var body: some View {
        Form {
            backupSection
            versionsSection
            iCloudSection
        }
        .formStyle(.grouped)
        .onAppear { refreshSnapshots() }
        .fileExporter(
            isPresented: $isExporting,
            document: exportPayload,
            contentType: .json,
            defaultFilename: "relay-backup-\(datestamp()).json"
        ) { result in
            switch result {
            case .success: statusMessage = "Backup saved."
            case .failure(let e): statusMessage = "Export failed: \(e.localizedDescription)"
            }
            exportPayload = nil
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json]) { result in
            guard case .success(let url) = result else { return }
            Task { await restore(from: url) }
        }
    }

    // MARK: - Sections

    private var backupSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading) {
                    Text("Export a complete snapshot of your command library and workflows.")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                Spacer()
                Button("Backup Library…") {
                    Task { await prepareExport() }
                }
            }
            HStack {
                VStack(alignment: .leading) {
                    Text("Replace the current library with a previously exported backup.")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                Spacer()
                Button("Restore from Backup…") {
                    isImporting = true
                }
            }
            if let msg = statusMessage {
                Text(msg).font(.caption).foregroundStyle(.secondary)
            }
        } header: {
            Text("Backup & Restore")
        }
    }

    private var versionsSection: some View {
        Section {
            if snapshots.isEmpty {
                Text("No auto-snapshots yet. Relay creates one every time the library is saved (keeps last 10).")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(Array(snapshots.enumerated()), id: \.offset) { _, url in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(snapshotLabel(url))
                                .font(.system(.body, design: .monospaced))
                            Text(snapshotDate(url))
                                .font(.caption).foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Button("Restore") {
                            Task { await restoreSnapshot(url) }
                        }
                        .buttonStyle(.bordered)
                        .foregroundStyle(.orange)
                    }
                }
            }
        } header: {
            Text("Version History")
        } footer: {
            Text("Restoring replaces your current library immediately. Back up first if you have unsaved changes.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var iCloudSection: some View {
        Section {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("iCloud Sync — Ready")
                        .font(.body)
                    Text("The library is architected for iCloud synchronisation. Full sync is available in the signed App Store release.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "icloud")
                    .foregroundStyle(.blue)
            }
        } header: {
            Text("iCloud")
        }
    }

    // MARK: - Actions

    private func prepareExport() async {
        let commands = (try? await environment.commandStore.loadCommands()) ?? []
        let tasks = (try? await environment.taskLibrary.store.loadTasks()) ?? []
        let payload = BackupBundle(commands: commands, tasks: tasks)
        exportPayload = payload
        isExporting = true
    }

    private func restore(from url: URL) async {
        do {
            let data = try Data(contentsOf: url)
            let bundle = try JSONDecoder().decode(BackupBundle.self, from: data)
            try await environment.commandStore.save(bundle.commands)
            try await environment.taskLibrary.store.save(bundle.tasks)
            await environment.library.load()
            await environment.taskLibrary.load()
            await MainActor.run { statusMessage = "Restored \(bundle.commands.count) commands and \(bundle.tasks.count) workflows." }
        } catch {
            await MainActor.run { statusMessage = "Restore failed: \(error.localizedDescription)" }
        }
    }

    private func restoreSnapshot(_ url: URL) async {
        guard let store = environment.commandStore as? JSONCommandStore else { return }
        do {
            try await store.restore(from: url)
            await environment.library.load()
            refreshSnapshots()
            statusMessage = "Restored from \(snapshotLabel(url))."
        } catch {
            statusMessage = "Snapshot restore failed: \(error.localizedDescription)"
        }
    }

    private func refreshSnapshots() {
        guard let store = environment.commandStore as? JSONCommandStore else { return }
        Task {
            let urls = await store.snapshots()
            await MainActor.run { snapshots = urls }
        }
    }

    // MARK: - Helpers

    private func snapshotLabel(_ url: URL) -> String {
        url.deletingPathExtension().lastPathComponent
    }

    private func snapshotDate(_ url: URL) -> String {
        guard let mod = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate else { return "" }
        return mod.formatted(.relative(presentation: .named))
    }

    private func datestamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}

// MARK: - Backup document

/// A Codable, FileDocument that wraps the full library for export.
struct BackupBundle: Codable, FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let commands: [RelayCommand]
    let tasks: [RelayTask]
    let exportedAt: Date

    init(commands: [RelayCommand], tasks: [RelayTask]) {
        self.commands = commands
        self.tasks = tasks
        self.exportedAt = Date()
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self = try JSONDecoder().decode(BackupBundle.self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(self)
        return FileWrapper(regularFileWithContents: data)
    }
}
