import SwiftUI
import RelayCore

/// The menu bar dropdown: a hierarchical command browser plus quick actions.
///
/// In Milestone 1, selecting a command opens the palette; direct execution from the menu
/// arrives with the execution engine in Milestone 3.
struct MenuBarContent: View {

    let environment: AppEnvironment
    let onOpenPalette: () -> Void

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Open Command Palette") { onOpenPalette() }
            .keyboardShortcut(.space, modifiers: .option)

        Button("Manage Commands…") { openWindow(id: WindowID.library) }
            .keyboardShortcut("l", modifiers: .command)

        Divider()

        if categories.isEmpty {
            Text("No commands yet")
        } else {
            ForEach(categories, id: \.self) { category in
                Menu(category) {
                    ForEach(commands(in: category)) { command in
                        Button {
                            onOpenPalette()
                        } label: {
                            Label(command.name, systemImage: command.icon)
                        }
                    }
                }
            }
        }

        Divider()

        SettingsLink {
            Text("Settings…")
        }
        .keyboardShortcut(",", modifiers: .command)

        Button("Quit Relay") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }

    private var commandsSnapshot: [RelayCommand] {
        environment.library.commands
    }

    private var categories: [String] {
        Array(Set(commandsSnapshot.map(\.category))).sorted()
    }

    private func commands(in category: String) -> [RelayCommand] {
        commandsSnapshot
            .filter { $0.category == category }
            .sorted { $0.name < $1.name }
    }
}
