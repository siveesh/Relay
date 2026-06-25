import SwiftUI
import RelayCore
import RelayUI

/// The workflow management window: browse, run, add, edit, and delete tasks.
struct TaskLibraryView: View {

    @Bindable var taskLibrary: TaskLibraryModel
    let runCoordinator: RunCoordinator

    @State private var selection: RelayTask.ID?
    @State private var editing: EditingTask?

    var body: some View {
        NavigationSplitView {
            List(taskLibrary.tasks, selection: $selection) { task in
                HStack(spacing: 10) {
                    Image(systemName: task.icon).foregroundStyle(RelayTheme.accentGradient).frame(width: 20)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(task.name)
                        Text("\(task.steps.count) step\(task.steps.count == 1 ? "" : "s")")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button { runCoordinator.requestRun(task) } label: {
                        Image(systemName: "play.fill")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(RelayTheme.cyan)
                    .help("Run task")
                }
                .tag(task.id)
                .contextMenu {
                    Button("Run") { runCoordinator.requestRun(task) }
                    Button("Edit") { editing = EditingTask(task: task) }
                    Divider()
                    Button("Delete", role: .destructive) { taskLibrary.delete(task) }
                }
            }
            .frame(minWidth: 260)
        } detail: {
            detail
        }
        .navigationTitle("Workflows")
        .toolbar {
            ToolbarItem {
                Button { editing = EditingTask(task: nil) } label: { Label("Add", systemImage: "plus") }
                    .keyboardShortcut("n", modifiers: .command)
            }
        }
        .sheet(item: $editing) { state in
            TaskEditorView(
                task: state.task,
                onSave: { task in
                    if state.task == nil { taskLibrary.add(task) } else { taskLibrary.update(task) }
                    selection = task.id
                    editing = nil
                },
                onCancel: { editing = nil }
            )
        }
    }

    @ViewBuilder private var detail: some View {
        if let task = taskLibrary.tasks.first(where: { $0.id == selection }) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: task.icon).font(.system(size: 28)).foregroundStyle(RelayTheme.accentGradient)
                        VStack(alignment: .leading) {
                            Text(task.name).font(.title2.bold())
                            if !task.details.isEmpty { Text(task.details).foregroundStyle(.secondary) }
                        }
                        Spacer()
                        Button("Run") { runCoordinator.requestRun(task) }.buttonStyle(.borderedProminent)
                        Button("Edit") { editing = EditingTask(task: task) }
                    }
                    ForEach(Array(task.steps.enumerated()), id: \.element.id) { index, step in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1)").font(.caption.monospacedDigit().bold())
                                .frame(width: 18).foregroundStyle(.secondary)
                            Text(describe(step)).font(.callout)
                            Spacer()
                        }
                        .padding(10)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(24)
            }
        } else {
            ContentUnavailableView("No Workflow Selected", systemImage: "list.bullet.rectangle",
                                   description: Text("Select a workflow to view its steps, or add a new one."))
        }
    }

    private func describe(_ step: TaskStep) -> String {
        switch step.kind {
        case let .shell(c, s): return "Shell (\(s)): \(c)"
        case let .launchApp(b): return "Launch app: \(b)"
        case let .quitApp(b): return "Quit app: \(b)"
        case let .delay(s): return "Delay \(s)s"
        case let .waitUntil(c): return "Wait until: \(c)"
        case let .httpHealthCheck(u, s): return "HTTP check \(u) == \(s)"
        case let .appleScript(s): return "AppleScript: \(s.prefix(60))"
        case let .javaScriptForAutomation(s): return "JXA: \(s.prefix(60))"
        case let .notify(t, b): return "Notify: \(t) — \(b)"
        }
    }
}

private struct EditingTask: Identifiable {
    let id = UUID()
    let task: RelayTask?
}
