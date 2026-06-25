# Relay Product Specification

## Purpose

Relay is a native macOS utility that lets users run shell commands, command groups, and automation tasks from a Spotlight-style command palette or optional menu bar dropdown.

It is not intended to be a general launcher like Raycast or Alfred. It is focused on commands, task execution, and lightweight workflow automation.

## Core Features

- Global hotkey command palette
- Fuzzy search
- Menu bar command browser
- Saved commands
- Multi-step tasks
- Variables
- Command packs
- Execution logs
- Native notifications
- Touch ID support for sudo/elevated commands
- Optional privileged helper for curated system operations

## Primary UI

A floating Liquid Glass command palette with:
- Search field
- Top result
- Recent commands
- Favorites
- Category badges
- Keyboard navigation

## Secondary UI

Menu bar icon with dropdown categories:
- AI
- Development
- Network
- System
- Media
- Custom user categories

## Command Object

Each command should support:

- id
- name
- description
- category
- icon
- tags
- aliases
- shell
- workingDirectory
- environment
- command
- timeoutSeconds
- requiresConfirmation
- requiresElevation
- runInBackground
- captureOutput
- notifyOnCompletion
- keyboardShortcut
- favorite

## Task Runner

Task steps may include:
- Execute shell command
- Launch app
- Quit app
- Wait
- Delay
- HTTP health check
- AppleScript
- JavaScript for Automation
- Notification
- Conditional branch
- Retry
- Stop on failure

## Security Model

Relay must never store admin passwords.

For user-authored sudo commands:
- Use normal macOS sudo authentication
- Support Touch ID-enabled sudo where configured
- Provide setup detection and guidance

For built-in privileged operations:
- Use a signed privileged helper
- Expose only predefined safe operations
- Never expose arbitrary command execution through the helper

## Liquid Glass Design

Relay should use:
- Rounded glass panels
- Subtle translucency
- macOS vibrancy
- Light/dark adaptive UI
- Native typography
- Smooth transitions
- Minimal visual clutter

## App Icon

Concept:
- Rounded macOS app icon
- Blue/cyan Liquid Glass depth
- White forward chevron
- Symbol meaning: relay, execution, forward motion, command handoff
