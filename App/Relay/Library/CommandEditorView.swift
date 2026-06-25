import SwiftUI
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
                    TextField("Working directory", text: $draft.workingDirectory)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Command").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $draft.command)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 70)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(.quaternary))
                    }
                    Stepper("Timeout: \(draft.timeoutSeconds)s", value: $draft.timeoutSeconds, in: 0...3600, step: 5)
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
    }

    func command(basedOn original: RelayCommand?) -> RelayCommand {
        RelayCommand(
            id: original?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            details: details,
            category: category.isEmpty ? "General" : category,
            icon: icon.isEmpty ? "chevron.right.circle.fill" : icon,
            tags: splitList(tagsText),
            aliases: splitList(aliasesText),
            shell: shell,
            workingDirectory: workingDirectory,
            environment: original?.environment ?? [:],
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
