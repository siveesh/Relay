# Relay Implementation Prompt

You are building Relay, a premium native macOS application.

## Objective

Create a lightweight command palette and task runner that allows users to execute saved terminal commands and multi-step workflows without opening Terminal.

## Required Implementation

Build a native macOS Swift/SwiftUI app with:

1. Menu bar app lifecycle
2. Optional dock icon preference
3. Global hotkey command palette
4. Fuzzy command search
5. Command model
6. JSON command storage
7. Command execution using Process
8. stdout/stderr capture
9. Exit-code reporting
10. Native notifications
11. Settings screen
12. Sample command pack import
13. Touch ID sudo detection guidance
14. Security-first architecture
15. Liquid Glass-inspired UI

## Important Security Requirements

- Do not store passwords.
- Do not bypass macOS security.
- Do not implement custom privilege escalation.
- Sudo commands must use system authentication.
- Privileged helper must be limited to curated operations only.
- Generated commands, if AI support is added later, must never execute without user approval.

## Initial MVP

Build the first version with:

- Command palette
- Menu bar dropdown
- Add/edit/delete commands
- Execute command
- View output
- Sample commands
- Import/export JSON
- Settings

## Future Hooks

Prepare architecture for:

- Task runner
- Command packs
- AI command suggestions
- Privileged helper
- Sync
- SSH/remote execution

## Style

The app should feel:
- Fast
- Native
- Minimal
- Premium
- Secure
- Focused

Avoid building a Raycast clone. Relay is a command-focused tool, not a general launcher.
