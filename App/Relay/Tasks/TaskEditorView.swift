import SwiftUI
import RelayCore

/// Sheet for creating or editing a workflow task and its steps.
struct TaskEditorView: View {

    let original: RelayTask?
    let onSave: (RelayTask) -> Void
    let onCancel: () -> Void

    @State private var name: String
    @State private var details: String
    @State private var icon: String
    @State private var stopOnFailure: Bool
    @State private var steps: [EditableStep]

    init(task: RelayTask?, onSave: @escaping (RelayTask) -> Void, onCancel: @escaping () -> Void) {
        self.original = task
        self.onSave = onSave
        self.onCancel = onCancel
        _name = State(initialValue: task?.name ?? "")
        _details = State(initialValue: task?.details ?? "")
        _icon = State(initialValue: task?.icon ?? "list.bullet.rectangle")
        _stopOnFailure = State(initialValue: task?.stopOnFailure ?? true)
        _steps = State(initialValue: (task?.steps ?? []).map(EditableStep.init(step:)))
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(original == nil ? "New Task" : "Edit Task")
                .font(.headline).padding(.top, 16)

            Form {
                Section("Task") {
                    TextField("Name", text: $name)
                    TextField("Description", text: $details)
                    TextField("SF Symbol", text: $icon)
                    Toggle("Stop on first failure", isOn: $stopOnFailure)
                }

                Section("Steps") {
                    ForEach($steps) { $step in
                        StepEditorRow(step: $step) { remove(step) }
                    }
                    .onMove { steps.move(fromOffsets: $0, toOffset: $1) }

                    Button {
                        steps.append(EditableStep())
                    } label: {
                        Label("Add Step", systemImage: "plus.circle")
                    }
                }
            }
            .formStyle(.grouped)

            Divider()
            HStack {
                Spacer()
                Button("Cancel", role: .cancel, action: onCancel).keyboardShortcut(.cancelAction)
                Button("Save") { onSave(buildTask()) }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || steps.isEmpty)
            }
            .padding(16)
        }
        .frame(width: 560, height: 680)
    }

    private func remove(_ step: EditableStep) {
        steps.removeAll { $0.id == step.id }
    }

    private func buildTask() -> RelayTask {
        RelayTask(
            id: original?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            details: details,
            icon: icon.isEmpty ? "list.bullet.rectangle" : icon,
            steps: steps.map { $0.toStep() },
            stopOnFailure: stopOnFailure,
            favorite: original?.favorite ?? false
        )
    }
}

/// One step's editing row: a kind picker plus the fields relevant to that kind.
private struct StepEditorRow: View {
    @Binding var step: EditableStep
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Picker("", selection: $step.kind) {
                    ForEach(EditableStep.Kind.allCases) { Text($0.label).tag($0) }
                }
                .labelsHidden()
                Spacer()
                Button(role: .destructive, action: onRemove) {
                    Image(systemName: "minus.circle")
                }
                .buttonStyle(.plain)
            }

            switch step.kind {
            case .shell:
                TextField("Command", text: $step.text1)
                TextField("Shell (zsh/bash/sh)", text: $step.text2)
            case .launchApp, .quitApp:
                TextField("Bundle identifier (e.g. com.apple.Safari)", text: $step.text1)
            case .delay:
                TextField("Seconds", text: $step.text2)
            case .waitUntil:
                TextField("Condition (shell command, success = exit 0)", text: $step.text1)
            case .httpHealthCheck:
                TextField("URL", text: $step.text1)
                TextField("Expected HTTP status", text: $step.text2)
            case .appleScript, .javaScript:
                TextField("Source", text: $step.text1)
            case .notify:
                TextField("Title", text: $step.text1)
                TextField("Body", text: $step.text2)
            }

            HStack {
                Toggle("Continue on error", isOn: $step.continueOnError).font(.caption)
                Spacer()
                Stepper("Retries: \(step.retryCount)", value: $step.retryCount, in: 0...5).font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

/// Mutable, string-backed representation of a `TaskStep` for editing.
private struct EditableStep: Identifiable {
    enum Kind: String, CaseIterable, Identifiable {
        case shell, launchApp, quitApp, delay, waitUntil, httpHealthCheck, appleScript, javaScript, notify
        var id: String { rawValue }
        var label: String {
            switch self {
            case .shell: return "Shell Command"
            case .launchApp: return "Launch App"
            case .quitApp: return "Quit App"
            case .delay: return "Delay"
            case .waitUntil: return "Wait Until"
            case .httpHealthCheck: return "HTTP Health Check"
            case .appleScript: return "AppleScript"
            case .javaScript: return "JavaScript (JXA)"
            case .notify: return "Notification"
            }
        }
    }

    let id: UUID
    var kind: Kind
    var text1: String
    var text2: String
    var continueOnError: Bool
    var retryCount: Int

    init() {
        id = UUID(); kind = .shell; text1 = ""; text2 = "zsh"; continueOnError = false; retryCount = 0
    }

    init(step: TaskStep) {
        id = step.id
        continueOnError = step.continueOnError
        retryCount = step.retryCount
        switch step.kind {
        case let .shell(command, shell): kind = .shell; text1 = command; text2 = shell
        case let .launchApp(b): kind = .launchApp; text1 = b; text2 = ""
        case let .quitApp(b): kind = .quitApp; text1 = b; text2 = ""
        case let .delay(s): kind = .delay; text1 = ""; text2 = String(s)
        case let .waitUntil(c): kind = .waitUntil; text1 = c; text2 = ""
        case let .httpHealthCheck(u, s): kind = .httpHealthCheck; text1 = u; text2 = String(s)
        case let .appleScript(s): kind = .appleScript; text1 = s; text2 = ""
        case let .javaScriptForAutomation(s): kind = .javaScript; text1 = s; text2 = ""
        case let .notify(t, b): kind = .notify; text1 = t; text2 = b
        }
    }

    func toStep() -> TaskStep {
        let kindValue: TaskStep.Kind
        switch kind {
        case .shell: kindValue = .shell(command: text1, shell: text2.isEmpty ? "zsh" : text2)
        case .launchApp: kindValue = .launchApp(bundleIdentifier: text1)
        case .quitApp: kindValue = .quitApp(bundleIdentifier: text1)
        case .delay: kindValue = .delay(seconds: Double(text2) ?? 1)
        case .waitUntil: kindValue = .waitUntil(condition: text1)
        case .httpHealthCheck: kindValue = .httpHealthCheck(url: text1, expectedStatus: Int(text2) ?? 200)
        case .appleScript: kindValue = .appleScript(source: text1)
        case .javaScript: kindValue = .javaScriptForAutomation(source: text1)
        case .notify: kindValue = .notify(title: text1, body: text2)
        }
        return TaskStep(id: id, kind: kindValue, continueOnError: continueOnError, retryCount: retryCount)
    }
}
