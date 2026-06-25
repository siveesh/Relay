# Relay

**Native macOS Command Palette & Task Runner**

Relay lets you execute shell commands and multi-step workflows without opening Terminal.
It is a focused command runner — *not* a general application launcher — built natively in
Swift/SwiftUI with a Liquid Glass interface.

> Status: **Milestones 1–7 complete** — full command palette, persistence & CRUD, real
> execution with logging and notifications, history-driven fuzzy search, a workflow/task
> runner with variables, security (Touch ID detection + privileged-helper design), and a
> polish pass (animation, accessibility, performance, docs).

See [ARCHITECTURE.md](ARCHITECTURE.md) and [SECURITY.md](SECURITY.md) for design detail.

## Requirements

- macOS 26 (Tahoe) or later
- Xcode 26+ / Swift 6.3+
- [XcodeGen](https://github.com/yonsm/XcodeGen) (`brew install xcodegen`)

## Project layout

```
Relay/
├── AI_INSTRUCTIONS.md      # Long-term goals, standards, architecture, constraints
├── RelayKit/               # Swift package: all logic + UI library modules
│   ├── Package.swift
│   ├── Sources/
│   │   ├── RelayCore/          # Models, execution engine, protocols (root module)
│   │   ├── RelayStorage/       # JSON persistence (SQLite-swappable)
│   │   ├── RelaySearch/        # Fuzzy search + ranking
│   │   ├── RelayTasks/         # Workflow / task runner
│   │   ├── RelaySecurity/      # sudo / Touch ID / privileged helper
│   │   ├── RelayNotifications/ # Native notifications
│   │   ├── RelayCommandPacks/  # Import / export packs
│   │   └── RelayUI/            # Liquid Glass components
│   └── Tests/
└── App/
    ├── project.yml         # XcodeGen spec for the Relay.app target
    └── Relay/              # App shell: lifecycle, menu bar, hotkey, palette panel
```

## Build & run

```bash
# 1. Library logic (fast iteration)
cd RelayKit && swift build && swift test

# 2. Generate and build the app
cd ../App && xcodegen generate
xcodebuild -project Relay.xcodeproj -scheme Relay -configuration Debug build
```

The generated `App/Relay.xcodeproj` is **not** committed — regenerate it with `xcodegen`.

## Roadmap

| Milestone | Scope |
|---|---|
| **M1** ✅ | Structure, architecture, menu bar lifecycle, command palette window |
| **M2** ✅ | Command model, JSON persistence, CRUD editor |
| **M3** ✅ | Shell execution, logging, notifications |
| **M4** ✅ | Fuzzy search, favorites, aliases, history |
| **M5** ✅ | Task runner, variables, workflow engine |
| **M6** ✅ | Security: Touch ID detection, privileged helper |
| **M7** ✅ | Polish: animation, accessibility, performance, docs |
