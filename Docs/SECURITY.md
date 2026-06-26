# Relay Security Model

Relay executes shell commands and workflows, so its security posture is central to the
design. These rules are non-negotiable (see also `AI_INSTRUCTIONS.md` §6).

## Principles

1. **No stored credentials.** Relay never stores passwords or admin credentials anywhere.
2. **No custom privilege escalation.** Relay never invents its own escalation path or
   bypasses macOS security.
3. **System authentication only.** Elevation always goes through macOS.
4. **Least privilege at the boundary.** The privileged helper exposes only a fixed, curated
   set of operations — never arbitrary command execution.
5. **No auto-execution of generated content.** Any future AI feature only *suggests* and
   *explains* commands; nothing it generates runs without explicit user approval.

## Elevation (user-authored `sudo` commands)

When a command is marked **Requires elevation**, Relay does not run `sudo` directly (there is
no TTY and Relay holds no password). Instead `AuthorizedExecutor`
(`RelayKit/Sources/RelaySecurity/AuthorizedExecutor.swift`) routes it through:

```
osascript -e 'do shell script "<command>" with administrator privileges'
```

This triggers the standard macOS authentication dialog — and Touch ID where the user has
configured it. Inline `sudo` is stripped (the whole script already runs as root), and all
quoting is escaped robustly for both AppleScript and the shell.

## Touch ID for `sudo`

`SudoDetector` (`RelayKit/Sources/RelaySecurity/SudoDetector.swift`) **detects only**:

- Touch ID hardware presence via `LAContext`.
- Whether `pam_tid.so` is configured in `/etc/pam.d/sudo_local` or `/etc/pam.d/sudo`.

Relay **never edits** PAM configuration. When Touch ID hardware is present but unconfigured,
the Security settings pane shows copyable guidance the user can run themselves:

```
echo 'auth       sufficient     pam_tid.so' | sudo tee /etc/pam.d/sudo_local
```

## Privileged helper (curated operations)

For built-in privileged actions, Relay's design uses Apple's `ServiceManagement`
(`SMAppService`) helper architecture
(`RelayKit/Sources/RelaySecurity/PrivilegedHelper.swift`):

- `PrivilegedOperation` is a **fixed, parameterless enum** (e.g. `flushDNSCache`,
  `renewDHCPLease`). The helper exposes only these — there is no "run this string as root"
  entry point, by construction.
- `ServiceManagementHelperClient` registers/reports status via `SMAppService` and would call
  the helper over a validated `NSXPCConnection` (the helper checks the client's code-signing
  requirement).

> The signed helper executable + XPC service are a packaging step requiring a signed build;
> until it ships, `perform(_:)` returns `.unavailable`. The architecture and the curated
> boundary are in place now.

## Distribution

The current build is **local/unsigned and non-sandboxed** so it can run arbitrary user shell
commands across arbitrary paths. App Sandbox is fundamentally incompatible with that purpose;
notarization/Developer ID and any sandbox-compatible subset are revisited before distribution.
