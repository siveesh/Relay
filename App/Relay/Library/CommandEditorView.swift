import SwiftUI
import UniformTypeIdentifiers
import RelayCore

/// Sheet for creating or editing a single command. Edits a local draft and commits on Save.
struct CommandEditorView: View {

    /// `nil` when creating a new command.
    let original: RelayCommand?
    let onSave: (RelayCommand) -> Void
    let onCancel: () -> Void

    @State private var draft: Draft

    init(command: RelayCommand?, onSave: @escaping (RelayCommand) -> Void, onCancel: @escaping () -> Void) {
        self.original = command
        self.onSave = onSave
        self.onCancel = onCancel
        _draft = State(initialValue: Draft(command: command))
    }

    private let shells = ["zsh", "bash", "sh"]

    var body: some View {
        VStack(spacing: 0) {
            Text(original == nil ? "New Command" : "Edit Command")
                .font(.headline)
                .padding(.top, 16)

            Form {
                Section("Command") {
                    TextField("Name", text: $draft.name)
                    TextField("Description", text: $draft.details)
                    TextField("Category", text: $draft.category)
                    TextField("SF Symbol", text: $draft.icon)
                }

                Section("Execution") {
                    Picker("Shell", selection: $draft.shell) {
                        ForEach(shells, id: \.self) { Text($0) }
                    }
                    WorkingDirectoryField(path: $draft.workingDirectory)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Command").font(.caption).foregroundStyle(.secondary)
                        CommandTextEditor(text: $draft.command)
                    }
                    Stepper("Timeout: \(draft.timeoutSeconds)s", value: $draft.timeoutSeconds, in: 0...3600, step: 5)
                }

                Section("Environment") {
                    ForEach(Array(draft.environmentEntries.enumerated()), id: \.offset) { index, entry in
                        HStack(spacing: 6) {
                            TextField("KEY", text: $draft.environmentEntries[index].key)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: 140)
                            Text("=").foregroundStyle(.secondary)
                            TextField("value", text: $draft.environmentEntries[index].value)
                                .font(.system(.body, design: .monospaced))
                            Button(role: .destructive) {
                                draft.environmentEntries.remove(at: index)
                            } label: {
                                Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Button {
                        draft.environmentEntries.append(EnvEntry(key: "", value: ""))
                    } label: {
                        Label("Add Variable", systemImage: "plus.circle")
                    }
                }

                Section("Discovery") {
                    TextField("Tags (comma-separated)", text: $draft.tagsText)
                    TextField("Aliases (comma-separated)", text: $draft.aliasesText)
                    TextField("Keyboard shortcut", text: $draft.keyboardShortcut)
                    Toggle("Favorite", isOn: $draft.favorite)
                }

                Section("Behaviour") {
                    Toggle("Requires confirmation", isOn: $draft.requiresConfirmation)
                    Toggle("Requires elevation (sudo)", isOn: $draft.requiresElevation)
                    Toggle("Run in background", isOn: $draft.runInBackground)
                    Toggle("Capture output", isOn: $draft.captureOutput)
                    Toggle("Notify on completion", isOn: $draft.notifyOnCompletion)
                }
            }
            .formStyle(.grouped)

            Divider()
            HStack {
                Spacer()
                Button("Cancel", role: .cancel, action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button("Save") { onSave(draft.command(basedOn: original)) }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty
                              || draft.command.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(16)
        }
        .frame(width: 520, height: 640)
    }
}

/// Key-value pair for environment variable editing.
private struct EnvEntry {
    var key: String
    var value: String
}

/// Mutable, string-friendly working copy of a command used while editing.
private struct Draft {
    var name: String
    var details: String
    var category: String
    var icon: String
    var shell: String
    var workingDirectory: String
    var command: String
    var timeoutSeconds: Int
    var tagsText: String
    var aliasesText: String
    var keyboardShortcut: String
    var favorite: Bool
    var requiresConfirmation: Bool
    var requiresElevation: Bool
    var runInBackground: Bool
    var captureOutput: Bool
    var notifyOnCompletion: Bool
    var environmentEntries: [EnvEntry]

    init(command: RelayCommand?) {
        name = command?.name ?? ""
        details = command?.details ?? ""
        category = command?.category ?? "General"
        icon = command?.icon ?? "chevron.right.circle.fill"
        shell = command?.shell ?? "zsh"
        workingDirectory = command?.workingDirectory ?? "~"
        self.command = command?.command ?? ""
        timeoutSeconds = command?.timeoutSeconds ?? 60
        tagsText = (command?.tags ?? []).joined(separator: ", ")
        aliasesText = (command?.aliases ?? []).joined(separator: ", ")
        keyboardShortcut = command?.keyboardShortcut ?? ""
        favorite = command?.favorite ?? false
        requiresConfirmation = command?.requiresConfirmation ?? false
        requiresElevation = command?.requiresElevation ?? false
        runInBackground = command?.runInBackground ?? false
        captureOutput = command?.captureOutput ?? true
        notifyOnCompletion = command?.notifyOnCompletion ?? false
        environmentEntries = (command?.environment ?? [:])
            .sorted { $0.key < $1.key }
            .map { EnvEntry(key: $0.key, value: $0.value) }
    }

    func command(basedOn original: RelayCommand?) -> RelayCommand {
        var env: [String: String] = [:]
        for entry in environmentEntries where !entry.key.isEmpty {
            env[entry.key] = entry.value
        }
        return RelayCommand(
            id: original?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            details: details,
            category: category.isEmpty ? "General" : category,
            icon: icon.isEmpty ? "chevron.right.circle.fill" : icon,
            tags: splitList(tagsText),
            aliases: splitList(aliasesText),
            shell: shell,
            workingDirectory: workingDirectory,
            environment: env,
            command: command,
            timeoutSeconds: timeoutSeconds,
            requiresConfirmation: requiresConfirmation,
            requiresElevation: requiresElevation,
            runInBackground: runInBackground,
            captureOutput: captureOutput,
            notifyOnCompletion: notifyOnCompletion,
            keyboardShortcut: keyboardShortcut.isEmpty ? nil : keyboardShortcut,
            favorite: favorite
        )
    }

    private func splitList(_ text: String) -> [String] {
        text.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}

// MARK: - Drag-and-drop subviews

/// Working directory text field that accepts dropped folders (or files, using their parent).
private struct WorkingDirectoryField: View {
    @Binding var path: String
    @State private var isTargeted = false

    var body: some View {
        TextField("Working directory", text: $path)
            .overlay(alignment: .trailing) {
                if isTargeted {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(.blue, lineWidth: 2)
                        .allowsHitTesting(false)
                }
            }
            .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted) { providers in
                guard let provider = providers.first else { return false }
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                    guard let data = item as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                    var dir = url.path
                    var isDirectory: ObjCBool = false
                    if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
                       !isDirectory.boolValue {
                        dir = url.deletingLastPathComponent().path
                    }
                    DispatchQueue.main.async { path = dir }
                }
                return true
            }
            .help("Drag a folder here to set the working directory")
    }
}

/// Monospaced TextEditor for the command body that accepts dropped file/folder paths.
private struct CommandTextEditor: View {
    @Binding var text: String
    @State private var isTargeted = false

    var body: some View {
        TextEditor(text: $text)
            .font(.system(.body, design: .monospaced))
            .frame(minHeight: 70)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isTargeted ? Color.blue : Color(.quaternaryLabelColor), lineWidth: isTargeted ? 2 : 1)
            )
            .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted) { providers in
                var paths: [String] = []
                let group = DispatchGroup()
                for provider in providers {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                        defer { group.leave() }
                        guard let data = item as? Data,
                              let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                        paths.append("'\(url.path)'")
                    }
                }
                group.notify(queue: .main) {
                    guard !paths.isEmpty else { return }
                    let insertion = paths.joined(separator: " ")
                    if text.isEmpty || text.hasSuffix(" ") || text.hasSuffix("\n") {
                        text += insertion
                    } else {
                        text += " " + insertion
                    }
                }
                return true
            }
            .help("Drag files or folders here to insert their paths")
    }
}
