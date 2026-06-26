# Relay Architecture

Relay is a native macOS command palette & task runner. The codebase is a thin SwiftUI/AppKit
app shell over a modular Swift package of pure, testable logic.

## Layout

```
RelayKit/ (Swift package)        App/ (XcodeGen-generated app)
  RelayCore        ← root          Relay/
  RelayStorage                       RelayApp.swift        @main, scenes (MenuBarExtra + Windows)
  RelaySearch                        AppDelegate.swift     lifecycle, hotkey, panels, load
  RelayTasks                         AppEnvironment.swift  composition root (DI)
  RelaySecurity                      GlobalHotKey.swift    Carbon ⌥Space
  RelayNotifications                 PalettePanelController.swift
  RelayCommandPacks                  Library/   Tasks/   Execution/   Security/
  RelayUI
```

## Module responsibilities & dependencies

`RelayCore` depends on nothing else in the kit; every other module depends on it. The graph
is a DAG, so each layer is independently unit-testable.

| Module | Responsibility |
|---|---|
| `RelayCore` | Models (`RelayCommand`, `RelayTask`, `TaskStep`, `CommandPack`, `ExecutionRecord`, `UsageStats`), `ShellExecutor`, `VariableResolver`, and the protocols defining every seam. |
| `RelayStorage` | `JSONCommandStore`, `JSONTaskStore`, `JSONHistoryStore`, `InMemoryCommandStore`. |
| `RelaySearch` | `FuzzySearchEngine` (subsequence match + favorites + usage ranking). |
| `RelayTasks` | `TaskRunner` actor + `StepExecutor` (all step kinds, retries, conditions). |
| `RelaySecurity` | `AuthorizedExecutor`, `SudoDetector`, privileged-helper client. |
| `RelayNotifications` | `UNUserNotificationCenter` wrapper. |
| `RelayCommandPacks` | Lenient pack DTO + slug→UUID import, idempotent merge, export. |
| `RelayUI` | Liquid Glass palette, rows, result view, design tokens, palette view model. |
| `Relay` (app) | Lifecycle, menu bar, hotkey, panels, windows, and the DI composition root. |

## Cross-cutting design

- **Protocol-based DI.** `AppEnvironment` is the only place that names concrete types; it
  injects `CommandStoring`, `CommandSearching`, `CommandExecuting`, `VariableResolving`,
  `NotificationPosting`, `TaskStoring`, `HistoryStoring` everywhere else.
- **Concurrency.** Execution lives behind actors (`ShellExecutor`, `TaskRunner`); models are
  `Sendable`; view models and coordinators are `@MainActor @Observable`. Swift 6 strict mode.
- **MVVM.** SwiftUI views are dumb; state lives in `@Observable` models
  (`CommandLibraryModel`, `TaskLibraryModel`, `HistoryModel`, `CommandPaletteModel`, …).
- **Persistence.** JSON behind protocols, so SQLite can replace any store with no call-site
  changes.

## Execution flow

```
hotkey / menu → palette → RunCoordinator.requestRun(command)
  → confirmation (if required)
  → VariableResolver expands $vars in command/cwd/env
  → AuthorizedExecutor (elevation via macOS auth) → ShellExecutor
  → ExecutionRecord → HistoryModel (persisted) + notification + result panel
```

Workflows follow the same path through `TaskRunner` → `StepExecutor`, honouring retries,
`continueOnError`, and `stopOnFailure`.

## Extension points (defined, not yet implemented)

`CommandSuggesting` (AI, approval-gated), `PrivilegedHelperClient` (curated ops via
`ServiceManagement`), and the storage/execution protocols (sync / SSH remote execution).

## Building

```bash
cd RelayKit && swift build && swift test     # logic
cd App && xcodegen generate && xcodebuild -project Relay.xcodeproj -scheme Relay build
```

The `App/Relay.xcodeproj` is generated and not committed.
