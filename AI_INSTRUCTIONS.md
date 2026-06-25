# AI_INSTRUCTIONS — Relay

This file is the durable contract for any human or AI agent working on Relay. Read it
before making changes. It captures the product intent, engineering standards, architecture,
and the hard constraints that must never be violated.

---

## 1. Product

**Relay** is a premium, native macOS **command palette & task runner**. It executes saved
shell commands and multi-step workflows from a Spotlight-style floating palette and an
optional menu bar browser — without opening Terminal.

**Relay is not** a general application launcher and must not drift into being a Raycast /
Alfred clone. Every feature must serve *command execution, workflow automation, or system
administration*, while staying lightweight and deeply native.

Design north stars: **simplicity · performance · native appearance · security ·
maintainability · extensibility.**

---

## 2. Long-term goals

- Ship-quality enough to plausibly appear on the Mac App Store (distribution target is
  revisited later; current build is local/unsigned, non-sandboxed).
- A command runner that feels instant and invisible until summoned.
- A workflow engine that grows from single commands to rich, conditional multi-step tasks.
- A security posture users can trust with elevated/system operations.
- Clean extension points so AI assistance, sync, and remote execution can be added later
  without re-architecting.

---

## 3. Engineering standards

- **Language**: Swift 6, strict concurrency (Swift 6 language mode). No data races.
- **UI**: SwiftUI first; AppKit only where SwiftUI cannot reach (panels, global hotkey).
- **Concurrency**: `actor`s for execution and shared mutable state; `Sendable` models;
  UI types on `@MainActor`. Long work off the main actor. Cooperative cancellation.
- **Architecture**: MVVM. Views are dumb; `@Observable @MainActor` view models hold state.
- **Dependency Injection**: protocol-based services resolved at a single composition root
  (`AppEnvironment`). No hidden singletons; no service constructs its own dependencies.
- **Persistence**: JSON first, always behind a protocol (`CommandStoring`) so SQLite can
  replace it with zero call-site changes.
- **Quality**: no duplication; composition over inheritance; document non-obvious
  decisions; unit-test critical logic (models, search, execution, task engine).
- **Modules stay loosely coupled** — respect the dependency DAG (see §5). `RelayCore` never
  imports another Relay module.
- Match the style, naming, and comment density of surrounding code. Public API is
  documented; internal code is clear over clever.

---

## 4. Performance budgets (treat as requirements)

| Metric | Budget |
|---|---|
| Cold launch | < 150 ms |
| Idle memory | < 40 MB |
| Idle CPU | ~ 0% |
| Search latency | < 20 ms |

Keep the app target thin, lazy-load stores, and never block the main actor.

---

## 5. Architecture & module boundaries

Local Swift package **`RelayKit`** holds all logic + UI library modules. A thin XcodeGen-
generated **`Relay`** app target is the composition root and owns AppKit/lifecycle surface.

Dependency DAG (an arrow means "depends on"; `RelayCore` is the root and depends on nothing):

```
RelayCore  ← RelayStorage ← RelayCommandPacks
RelayCore  ← RelaySearch
RelayCore  ← RelayTasks
RelayCore  ← RelaySecurity
RelayCore  ← RelayNotifications
RelayCore  ← RelayUI
Relay (app) → all modules
```

| Module | Responsibility |
|---|---|
| `RelayCore` | Domain models (`RelayCommand`, `RelayTask`, `TaskStep`, `CommandPack`), execution engine (`ShellExecutor`), variable resolution, and the protocols that define every extension seam. |
| `RelayStorage` | `JSONCommandStore`, `InMemoryCommandStore`, history; persistence behind `CommandStoring`. |
| `RelaySearch` | `FuzzySearchEngine` + ranking (exact / alias / favorite / frequency / recency). |
| `RelayTasks` | `TaskRunner`, `StepExecutor`, retry, health checks. |
| `RelaySecurity` | sudo detection, Touch ID status, privileged-helper client, permission prompts. |
| `RelayNotifications` | Native `UserNotifications` wrapper. |
| `RelayCommandPacks` | Import / export / backup / restore of JSON command packs. |
| `RelayUI` | Reusable Liquid Glass components, design tokens, palette view + view model. |
| `Relay` (app) | NSApplication lifecycle, `MenuBarExtra`, global hotkey, floating palette panel, DI. |

---

## 6. Security constraints (NON-NEGOTIABLE)

- **Never** store passwords or admin credentials. Anywhere. Ever.
- **Never** bypass macOS security or implement custom privilege escalation.
- User-authored `sudo` commands use **system authentication** only; support Touch ID where
  the user has configured it; detect and *guide*, never reconfigure silently.
- The privileged helper (when built) uses Apple's `ServiceManagement` architecture and
  exposes **only a fixed set of curated operations**. It must **never** expose arbitrary
  shell execution.
- Any future AI feature **suggests and explains** commands and **requires explicit user
  approval**; generated commands must **never** auto-execute.

---

## 7. UI / design language

Apple's **Liquid Glass** (macOS 26). Use native `glassEffect` / `GlassEffectContainer`,
vibrancy, rounded continuous geometry, depth, smooth animation, adaptive light/dark, and
native typography. It should feel like Apple designed it — never like Electron, VS Code, or
a Windows port. Palette: deep blue glass, cyan highlights, white forward-chevron mark.

---

## 8. Extension points (defined now, implemented later)

- `CommandSuggesting` — AI suggestions (approval-gated, never auto-run).
- `PrivilegedHelperClient` — curated privileged operations via `ServiceManagement`.
- Sync / remote (SSH) execution — keep storage and execution behind protocols so these slot in.

---

## 9. Working style

Build incrementally, milestone by milestone. **Each milestone must compile and its tests
pass before moving on.** After each milestone: summarize progress, explain key decisions,
note technical debt, and recommend next steps. Do not generate large numbers of files
blindly. Do not continue past a milestone without confirmation.

---

## 10. Milestones

1. **M1** ✅ — Project structure, architecture, navigation, menu bar lifecycle, palette window.
2. **M2** ✅ — Command model finalized, JSON persistence, CRUD.
3. **M3** ✅ — Shell execution, logging, notifications.
4. **M4** ✅ — Search engine, favorites, aliases, history.
5. **M5** ✅ — Task runner, variables, workflow engine.
6. **M6** ✅ — Security: Touch ID detection, privileged helper design.
7. **M7** ✅ — Polish: animation, accessibility, performance, documentation.

All seven milestones are implemented. Future work lives at the extension points in §8 (AI
suggestions, the signed privileged-helper executable + XPC, sync / SSH remote execution) and
in revisiting distribution (notarization / sandbox subset).
