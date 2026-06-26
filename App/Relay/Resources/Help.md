# Relay Help

Relay is a native macOS command palette and task runner that lets you launch, search, and automate shell commands from anywhere on your Mac — instantly, without opening a terminal.

---

## Contents

1. [Getting Started](#1-getting-started)
2. [The Command Palette](#2-the-command-palette)
3. [The Menu Bar](#3-the-menu-bar)
4. [Command Library](#4-command-library)
5. [Creating and Editing Commands](#5-creating-and-editing-commands)
6. [Variables](#6-variables)
7. [Execution and Results](#7-execution-and-results)
8. [Workflows (Task Runner)](#8-workflows-task-runner)
9. [Execution History](#9-execution-history)
10. [Settings — General](#10-settings--general)
11. [Settings — Variables](#11-settings--variables)
12. [Settings — Security](#12-settings--security)
13. [Settings — Data (Backup & Versioning)](#13-settings--data-backup--versioning)
14. [Shell History Import](#14-shell-history-import)
15. [Drag-and-Drop](#15-drag-and-drop)
16. [Finder Services](#16-finder-services)
17. [Apple Shortcuts & Siri](#17-apple-shortcuts--siri)
18. [Command Packs (Import & Export)](#18-command-packs-import--export)
19. [Keyboard Reference](#19-keyboard-reference)
20. [File Locations](#20-file-locations)

---

## 1. Getting Started

Relay lives in the **menu bar** — you will see the ❯❯ icon at the top right of your screen. It has no Dock icon by default.

**Open the palette at any time** by pressing **⌥ Space** (or your custom shortcut). The floating glass panel appears in the centre of your screen, ready for a command.

On first launch Relay seeds your library with 50+ example commands across eight categories (AI, Development, Docker, MLX, LM Studio, Network, Homebrew, Synology, System). You can edit or delete any of them.

---

## 2. The Command Palette

The palette is Relay's primary interface. Press **⌥ Space** (or your configured shortcut) from anywhere on your Mac.

### Search bar

Type any part of a command **name**, **category**, **tag**, or **alias**. Relay uses fuzzy matching — you do not need to type exact words. Frequently-used commands rank higher.

| Element | Description |
|---|---|
| **❯❯ icon** | Indicates the palette is idle and ready |
| **↓ icon** | Appears when you drag a file onto the palette |

### Command list

Each row shows the command icon, name, category badge, and keyboard shortcut (if set).

- **↵ Return** — run the highlighted command
- **↑ / ↓ arrows** — move through results
- **Escape** — dismiss the palette

### Running a command

Press **Return** on the selected command. If the command requires confirmation a dialog appears first. If it requires elevation (sudo), macOS will present a Touch ID / password prompt via the system security framework — no passwords are stored by Relay.

---

## 3. The Menu Bar

Click the ❯❯ icon in the menu bar to open the dropdown.

| Item | Action |
|---|---|
| **Open Command Palette** | Shows the floating palette |
| *(category menus)* | Browse and run commands by category directly from the menu |
| **Manage Commands…** | Opens the Command Library window |
| **Import Shell History…** | Opens the Shell History Import window |
| **Workflows…** | Opens the Workflow (Task Runner) window |
| **Execution History…** | Opens the history log |
| **Settings…** | Opens the Settings window (**⌘ ,**) |
| **About Relay…** | Shows the About window |
| **Quit Relay** | Quits the app (**⌘ Q**) |

---

## 4. Command Library

**Menu Bar → Manage Commands…**

The library lists all your commands. Commands are grouped by category and sorted alphabetically within each group.

### Toolbar actions

| Button | Action |
|---|---|
| **Import** (↓) | Import a command pack JSON file |
| **Export** (↑) | Export the current selection as a command pack JSON |
| **+** | Create a new command |

### Per-command actions

Right-click any command (or click the `…` menu in its row) for:

- **Edit** — open the command editor
- **Favorite / Unfavorite** — pin to the top of search results
- **Delete** — permanently remove the command

### Filtering

Use the search field at the top of the library to filter by name, category, or tag.

---

## 5. Creating and Editing Commands

Click **+** in the Command Library toolbar, or right-click any command and choose **Edit**.

### Fields

| Field | Description |
|---|---|
| **Name** | Short label shown in the palette and menu bar |
| **Description** | Longer note shown in the detail row and history |
| **Category** | Groups commands in the menu bar and library (free text) |
| **Icon** | SF Symbol name (e.g. `terminal`, `globe`, `brain`) |
| **Tags** | Comma-separated words used in fuzzy search |
| **Aliases** | Alternative search terms (e.g. `gs` for Git Status) |
| **Shell** | Interpreter — `zsh` (default) or `bash` |
| **Working Directory** | Starting directory. Supports `~` and [variables](#6-variables). Drag a folder here to set it. |
| **Environment** | Extra environment variables as `KEY = value` rows |
| **Command** | The shell script to run. Supports [variables](#6-variables). Drag files here to insert quoted paths. |
| **Timeout** | Maximum execution time in seconds (`0` = no limit) |

### Behaviour flags

| Toggle | Meaning |
|---|---|
| **Require Confirmation** | Show a "Run?" dialog before executing |
| **Requires Elevation** | Run with sudo (macOS auth dialog, no stored password) |
| **Run in Background** | Execute without showing a foreground result panel |
| **Capture Output** | Capture and display stdout/stderr in the result panel |
| **Notify on Completion** | Send a macOS notification when done |
| **Favorite** | Pin this command to the top of palette results |

### Drag-and-drop into the editor

You can drag files or folders directly into the editor:

- **Working Directory field** — dropping a folder sets it as the working directory; dropping a file uses its parent folder
- **Command text area** — dropping files appends their quoted paths (`'/path/to/file'`) at the end of the command

---

## 6. Variables

Relay expands `$VariableName` tokens inside command text, working directories, and environment values before execution.

### Built-in variables

| Variable | Expands to |
|---|---|
| `$Home` | Your home directory (`/Users/you`) |
| `$Desktop` | `~/Desktop` |
| `$Downloads` | `~/Downloads` |
| `$Documents` | `~/Documents` |
| `$Clipboard` | Current clipboard text |
| `$SelectedFinderFiles` | Space-separated quoted paths of files selected in Finder |
| `$CurrentFinderFolder` | Path of the frontmost Finder window's folder |
| `$Date` | Today's date, `YYYY-MM-DD` |
| `$Time` | Current time, `HH:mm:ss` |
| `$Hostname` | Your Mac's hostname |
| `$Username` | Your macOS username |

### Custom variables

Defined in **Settings → Variables**. Common examples:

| Variable | Default value |
|---|---|
| `$NAS` | `/Volumes/NAS` |
| `$CurrentProject` | `~/Developer` |

You can add any name and value — for example `$API_KEY`, `$StagingHost`, `$MyProject`.

Changes take effect immediately for new executions without restarting the app.

### How variables work

- Unknown tokens (no match in built-ins or custom variables) are left **intact** in the command string, so you can safely use shell variables like `$HOME` or `$PATH` — Relay ignores them.
- `$SelectedFinderFiles` returns files wrapped in single quotes and space-separated, ready for shell use.

---

## 7. Execution and Results

### Foreground execution

When a command runs in the foreground, a glass panel appears showing a spinner and the command name with a **Cancel** button. Once the command finishes, the panel switches to show:

- Exit code (green = 0, red = non-zero)
- stdout output (scrollable)
- stderr output (if any)
- Execution time

Press **Escape** or click elsewhere to dismiss the result panel.

### Background execution

Commands with **Run in Background** enabled run silently. If **Notify on Completion** is also enabled, you will receive a macOS notification when done with the exit code.

### Cancellation

Click **Cancel** in the foreground panel, or the running process is terminated when the palette is dismissed.

### Elevated commands (sudo)

If a command is flagged **Requires Elevation**, Relay presents a macOS authentication dialog (Touch ID or password). The credential is held by the system's security framework for the duration of the session — Relay never stores or sees your password.

---

## 8. Workflows (Task Runner)

**Menu Bar → Workflows…**

Workflows let you chain multiple steps into a single automation. They run in order; you can configure each step to continue or stop if it fails.

### Opening the Workflow Editor

Click **+** in the Workflows toolbar to create a new workflow, or click any existing workflow to edit it.

### Workflow fields

| Field | Description |
|---|---|
| **Name** | Label shown in the workflow list |
| **Description** | Optional note |
| **Icon** | SF Symbol name |
| **Stop on Failure** | If on, the workflow stops at the first failed step |

### Step types

| Step | What it does |
|---|---|
| **Shell Command** | Runs a shell command (same as a library command) |
| **Launch App** | Opens an app by bundle identifier (e.g. `com.microsoft.VSCode`) |
| **Quit App** | Quits an app by bundle identifier |
| **Delay** | Waits a specified number of seconds |
| **Wait Until** | Polls a condition string until it is true |
| **HTTP Health Check** | Polls a URL until it responds with the expected HTTP status |
| **AppleScript** | Runs inline AppleScript source |
| **JavaScript (JXA)** | Runs inline JavaScript for Automation |
| **Notification** | Sends a macOS notification (title + body) |

Each step has:
- **Continue on Error** toggle — if on, the workflow moves to the next step even if this one fails
- **Retry Count** — number of times to retry on failure (before treating the step as failed)

### Sample workflows (pre-installed)

| Workflow | What it does |
|---|---|
| **AI Environment Ready** | Tailscale up → Mount NAS → Start LM Studio → Wait for API → Open Cursor + VS Code → Notify |
| **Morning Setup** | Tailscale up → Git pull → Brew upgrade → Open VS Code |
| **Docker Deploy** | Git pull → Docker Compose pull → Compose up → Health verify → Notify |

### Running a workflow

Click **Run** (▶) next to any workflow. Steps execute in sequence and each step's result is shown in the progress panel.

---

## 9. Execution History

**Menu Bar → Execution History…**

Shows a log of every command and workflow that has run. Each record includes:

- Command name and category
- Exit code
- Execution date and duration
- stdout / stderr output (expandable)

The history is stored locally and persists across app restarts. It is not included in the backup/restore bundle.

---

## 10. Settings — General

**⌘ ,** or **Menu Bar → Settings…**

| Setting | Description |
|---|---|
| **Show icon in Dock** | Show Relay as a regular Dock app (off by default — Relay is menu-bar only) |
| **Global Shortcut** | The hot key that opens the command palette. Click the recorder and press your desired combination to change it. |

### Changing the global shortcut

1. Click the key-recorder field next to **Global Shortcut**.
2. Press the modifier combination you want (e.g. **⌃⌘Space**).
3. Then press the key (e.g. **R**).
4. If the combination is already in use by another app, Relay will show a conflict warning and let you choose another.
5. Press **Escape** to cancel recording without changing.

The default is **⌥ Space**.

---

## 11. Settings — Variables

Add, edit, or delete custom `$VARIABLE = value` pairs used throughout your commands.

- Click **Add Variable** to append a new row.
- Click **−** on any row to remove it.
- Edits apply immediately — running commands already started are not affected.

The two pre-installed defaults are `$NAS` (`/Volumes/NAS`) and `$CurrentProject` (`~/Developer`). Override them here to match your setup.

See [Variables](#6-variables) for the full list of built-in variables.

---

## 12. Settings — Security

### Privileged Helper

Relay includes an optional privileged helper for a small, fixed set of system operations that require root access. The helper only ever performs the operations listed below — it does not accept arbitrary commands or shell strings.

**Curated operations:**

| Operation | What it does |
|---|---|
| Flush DNS Cache | Clears the macOS DNS resolver cache |
| Renew DHCP Lease | Releases and renews the primary network interface lease |
| Repair Permissions | Repairs file permissions on system directories |
| Restart Service | Restarts a launchd system service |
| Mount Protected Path | Mounts a volume at a protected path |
| Edit Protected File | Writes to a protected system configuration file |

**Installing the helper:**

Click **Install Helper…**. macOS will ask for your password once to install the helper daemon. After installation the status pill turns green.

> The helper is bundled in the signed release build. In an unsigned local build the status will show "not found" — this is expected.

---

## 13. Settings — Data (Backup & Versioning)

### Backup Library

Exports your entire command library and all workflows as a single JSON file. Click **Backup Library…**, choose a location, and save.

### Restore from Backup

Click **Restore from Backup…** and select a previously exported JSON file. This **replaces** your current library and workflows immediately.

> Tip: create a backup before restoring so you can recover if needed.

### Version History

Relay automatically takes a snapshot of your command library every time it is saved. The last 10 snapshots are kept in:

```
~/Library/Application Support/Relay/Snapshots/
```

Each snapshot appears in the list with its age. Click **Restore** next to any snapshot to roll back to that point.

### iCloud

Relay's data layer is architected for iCloud synchronisation. Full sync is available in the signed App Store release. In the local build, data is stored on-device only.

---

## 14. Shell History Import

**Menu Bar → Import Shell History…**

Relay can scan your shell history files and import selected commands into your library, saving you from re-creating commands you already use daily.

### Supported shells

- **Zsh** — reads `~/.zsh_history` (both plain and extended `: timestamp:elapsed;command` format)
- **Bash** — reads `~/.bash_history`

### How to import

1. Open **Import Shell History…** from the menu bar.
2. The list loads all unique, non-trivial commands found in your history files.
3. Use the **filter bar** to search for specific commands.
4. Tick the checkboxes next to the commands you want, or use **Select All**.
5. Click **Import (N)**.

Imported commands are added to the **Imported** category. Commands already in your library (matched by exact command string) are skipped automatically.

After import, the window removes the imported entries from the list so you can continue picking more without duplicates.

---

## 15. Drag-and-Drop

Relay supports drag-and-drop at three surfaces:

| Surface | What you can drop | Result |
|---|---|---|
| **Palette search bar** | Files or folders | Appends quoted path(s) to the query |
| **Working Directory field** (editor) | A folder | Sets the field to that folder path |
| **Working Directory field** (editor) | A file | Sets the field to the file's parent folder |
| **Command text area** (editor) | Files or folders | Appends `'path1' 'path2'` to the command text |

A blue border highlight indicates the drop target is active.

---

## 16. Finder Services

Relay registers two macOS Services, available in Finder's right-click context menu and the **Services** submenu of any application's menu bar.

| Service | Trigger | Action |
|---|---|---|
| **Run with Relay…** | Select files/folders, right-click → Services | Opens the palette with the file paths pre-filled in the search bar |
| **Open Relay Palette** | Any context → Services → Open Relay Palette | Opens the palette (no pre-fill) |

> Services may take a few seconds to appear the first time after installation. Log out and back in, or run `killall pbs` in Terminal if they do not appear.

---

## 17. Apple Shortcuts & Siri

Relay integrates with the macOS **Shortcuts** app and **Siri** via Apple's AppIntents framework.

### Available actions

| Action | What it does |
|---|---|
| **Open Relay Palette** | Summons the command palette (also works with Siri voice) |
| **Run Relay Command** | Runs any command from your library; output is returned as text |
| **Search Relay Commands** | Searches your library by name, category, or tag; returns matching names |

### Using Shortcuts

1. Open the **Shortcuts** app (**Finder → Applications → Shortcuts**).
2. Create a new Shortcut.
3. Search for **Relay** in the action browser.
4. Drag **Run Relay Command** into your shortcut and pick a command from the drop-down.
5. Run it from Shortcuts, the menu bar, or with a Siri phrase.

### Example Siri phrases

- *"Open Relay"*
- *"Run Git Status with Relay"*
- *"Execute Docker PS in Relay"*

---

## 18. Command Packs (Import & Export)

Command packs are JSON files that bundle one or more commands for sharing or backup.

### Exporting a pack

1. In the Command Library, select the commands you want to export (click to select, **⌘-click** for multiple).
2. Click the **Export** (↑) button in the toolbar.
3. Choose a file name and location.

The exported file is a standard JSON array of command objects that can be shared, versioned in git, or imported into another Relay installation.

### Importing a pack

1. In the Command Library, click the **Import** (↓) button.
2. Select a `.json` pack file.
3. Commands are merged into your library. Existing commands with the same ID are skipped.

### Pack JSON structure

```json
{
  "packName": "My Pack",
  "version": "1.0",
  "commands": [
    {
      "name": "Git Status",
      "description": "Show working tree status.",
      "category": "Development",
      "icon": "arrow.triangle.branch",
      "tags": ["git"],
      "aliases": ["gs"],
      "shell": "zsh",
      "workingDirectory": "$CurrentProject",
      "command": "git status",
      "timeoutSeconds": 15,
      "requiresConfirmation": false,
      "requiresElevation": false,
      "runInBackground": false,
      "captureOutput": true,
      "notifyOnCompletion": false,
      "favorite": true
    }
  ]
}
```

---

## 19. Keyboard Reference

### Palette

| Key | Action |
|---|---|
| **⌥ Space** | Open / close the palette (default; configurable) |
| **↑ / ↓** | Move selection |
| **↵ Return** | Run selected command |
| **Escape** | Dismiss palette |

### Command Library

| Key | Action |
|---|---|
| **⌘ N** | New command |
| **⌫ Delete** | Delete selected command (with confirmation) |
| **Space** | Preview selected command details |

### Workflows

| Key | Action |
|---|---|
| **⌘ N** | New workflow |
| **⌫ Delete** | Delete selected workflow |

### Settings

| Key | Action |
|---|---|
| **⌘ ,** | Open Settings |
| **Escape** | Cancel hotkey recording without saving |

---

## 20. File Locations

All Relay data is stored in standard macOS locations. You can inspect or back up these files directly.

| File | Path |
|---|---|
| **Command library** | `~/Library/Application Support/Relay/commands.json` |
| **Workflows** | `~/Library/Application Support/Relay/tasks.json` |
| **Execution history** | `~/Library/Application Support/Relay/history.json` |
| **Auto-snapshots** | `~/Library/Application Support/Relay/Snapshots/` |
| **User preferences** | `~/Library/Preferences/com.relay.app.plist` |

> Tip: open the `Relay` folder in Finder with:
> ```
> open ~/Library/Application\ Support/Relay
> ```

---

*Relay — Native macOS Command Palette & Task Runner*  
*© 2026 Siveesh Kodapully · learnwithsk.com*
