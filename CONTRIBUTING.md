# Contributing to Relay

Thank you for your interest in contributing. These guidelines keep the codebase coherent and the review process fast.

## Before you start

- Read [ARCHITECTURE.md](ARCHITECTURE.md) to understand the module structure and dependency graph.
- Read [SECURITY.md](SECURITY.md) for the non-negotiable security constraints.
- Check the open issues and pull requests to avoid duplicating work.

## Setting up the development environment

```bash
git clone https://github.com/siveesh/Relay.git
cd Relay/App
xcodegen generate          # generates Relay.xcodeproj
open Relay.xcodeproj
```

Run the test suite before every commit:

```bash
cd RelayKit && swift test
```

## Code standards

- **Swift 6 strict concurrency.** All code must compile without warnings under `SWIFT_STRICT_CONCURRENCY = complete`.
- **No stored credentials.** Never write passwords, tokens, or secrets to disk, UserDefaults, or the Keychain.
- **Protocol-based DI.** New concrete types belong behind the existing protocols in `RelayCore`. `AppEnvironment` is the only composition root.
- **No arbitrary shell execution in the helper.** The privileged helper exposes only the operations in `PrivilegedOperation`. Adding a capability requires a new case — never pass a raw shell string across the XPC boundary.
- **Comments only when the why is non-obvious.** Identifiers should be self-documenting.

## Pull request checklist

- [ ] `swift test` passes with zero failures
- [ ] New public API has a one-line doc comment
- [ ] UI changes tested on macOS 26 (both light and dark mode)
- [ ] No new compiler warnings
- [ ] `CHANGELOG.md` updated under `[Unreleased]`

## Reporting security issues

Do **not** open a public issue for security vulnerabilities. Email siveesh@learnwithsk.com with details. See [SECURITY.md](SECURITY.md).
