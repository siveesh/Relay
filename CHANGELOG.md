# Changelog

All notable changes to Relay are documented here.

---

## [1.0.0] — 2026-06-26

### Added

**Core features**
- Global hotkey command palette (Liquid Glass floating panel)
- Fuzzy search with usage-based ranking, aliases, and tags
- Full command CRUD editor with all execution parameters
- Shell execution via `zsh` / `bash` with live output panel
- Background execution mode with macOS notifications
- Elevation via macOS auth dialog (Touch ID supported, no stored passwords)
- Execution history log with stdout / stderr

**Variable system**
- 11 built-in variables: `$Home`, `$Desktop`, `$Downloads`, `$Documents`, `$Clipboard`, `$SelectedFinderFiles`, `$CurrentFinderFolder`, `$Date`, `$Time`, `$Hostname`, `$Username`
- Custom variable editor in Settings → Variables (`$NAS`, `$CurrentProject`, any name)
- Live update — changes propagate to running sessions without restart

**Workflow / Task Runner**
- 9 step types: Shell, Launch App, Quit App, Delay, Wait Until, HTTP Health Check, AppleScript, JavaScript (JXA), Notification
- Per-step continue-on-error and retry count
- Stop-on-failure flag per workflow
- Pre-installed workflows: AI Environment Ready, Morning Setup, Docker Deploy

**Command Library**
- 50+ sample commands across 8 packs: AI, Development / Git, Docker, MLX, LM Studio, Tailscale / Network, Homebrew / System, Synology
- Command Pack import / export as JSON
- Favorites, keyboard shortcuts, drag-and-drop into editor

**Integrations**
- Apple Shortcuts / Siri — Open Palette, Run Command, Search Commands intents
- Finder Services — "Run with Relay…" and "Open Relay Palette" in right-click menu
- Shell History Import — scan `~/.zsh_history` and `~/.bash_history`, bulk import
- Drag-and-drop file paths into palette search, working directory field, and command text editor

**Settings**
- Configurable global hotkey with conflict detection (HotKeyRecorderView)
- Custom variables tab
- Privileged Helper with curated operation grid (Flush DNS, Renew DHCP, Repair Permissions, Restart Service, Mount Protected Path, Edit Protected File)
- Data tab: full library backup / restore, auto-snapshots (last 10), iCloud-ready note

**Help**
- In-app help window (⌘ ?) rendering Help.md with sidebar table of contents and full-text search
- Help.md covers all 20 sections of the user manual

**About**
- About window with Learn with SK branding and app version
