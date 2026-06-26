# Installing Relay

## System requirements

- **macOS 26 (Tahoe)** or later
- Apple Silicon or Intel Mac

---

## Option A — Install from DMG (recommended)

1. **Download** `Relay.dmg` from the [Releases page](../../releases/latest).

2. **Open** the DMG by double-clicking it. A window appears showing the Relay app and your Applications folder.

3. **Drag** `Relay.app` onto the **Applications** folder shortcut in the DMG window.

4. **Eject** the DMG (drag it to the Trash, or right-click → Eject).

5. **First launch** — because Relay is not yet notarised, macOS will block it on the first open:

   - Open **Finder → Applications**, right-click `Relay.app`, and choose **Open**.
   - Click **Open** in the dialog that appears.
   - You will only need to do this once.

   > **Alternative:** run `xattr -dr com.apple.quarantine /Applications/Relay.app` in Terminal to clear the quarantine flag without the dialog.

6. **Allow Notifications** — Relay will ask for notification permission on first run. Click **Allow** so you receive completion alerts from background commands.

---

## Option B — Build from source

### Prerequisites

| Tool | Install |
|---|---|
| Xcode 26+ | [Mac App Store](https://apps.apple.com/app/xcode/id497799835) |
| XcodeGen | `brew install xcodegen` |

### Steps

```bash
# Clone the repository
git clone https://github.com/siveesh/Relay.git
cd Relay

# (Optional) build and test the Swift package alone
cd RelayKit && swift test && cd ..

# Generate the Xcode project
cd App && xcodegen generate

# Build in Release mode
xcodebuild -scheme Relay -configuration Release -destination 'platform=macOS' build

# Copy the built app to Applications
APP=$(find ~/Library/Developer/Xcode/DerivedData -name "Relay.app" -path "*/Release/*" | head -1)
cp -R "$APP" /Applications/Relay.app
open /Applications/Relay.app
```

---

## First-run setup

### 1. The menu bar icon

Relay appears as **❯❯** in the menu bar. It has no Dock icon by default (you can enable one in Settings → General).

### 2. Open the command palette

Press **⌥ Space** (Option + Space). The floating Liquid Glass panel appears in the centre of your screen.

> If ⌥ Space is taken by another app (e.g. Alfred, Raycast), change the shortcut in **Settings → General → Global Shortcut**. Click the recorder and press your preferred key combination.

### 3. Run your first command

Type `git` in the palette. Select *Git Status* and press **Return**. Relay runs the command in your `$CurrentProject` directory and shows the output.

### 4. Set your working paths

Open **Settings → Variables** (⌘ , → Variables tab) and set:

| Variable | Your value |
|---|---|
| `$CurrentProject` | Path to your main development folder (e.g. `/Users/you/Developer`) |
| `$NAS` | Mount point for your NAS, if you use one (e.g. `/Volumes/NAS`) |

### 5. Import your shell history (optional)

Click **Menu Bar → Import Shell History…** to scan `~/.zsh_history` and `~/.bash_history` and pick commands to add to your library.

---

## Granting permissions

Relay may request the following permissions. Each is optional but unlocks specific features.

| Permission | Why | Where to grant |
|---|---|---|
| **Notifications** | Completion alerts for background commands | System Settings → Notifications → Relay |
| **Accessibility** | Reading the frontmost Finder window path (`$CurrentFinderFolder`) | System Settings → Privacy & Security → Accessibility |
| **Full Disk Access** | Accessing files in protected directories | System Settings → Privacy & Security → Full Disk Access |

---

## Uninstalling

1. Quit Relay (Menu Bar → Quit Relay).
2. Delete `/Applications/Relay.app`.
3. To remove all data and preferences:

```bash
rm -rf ~/Library/Application\ Support/Relay
rm ~/Library/Preferences/com.relay.app.plist
```

---

## Troubleshooting

### The palette does not open

- Make sure Relay is running (❯❯ icon in the menu bar).
- Check for hotkey conflicts in **Settings → General → Global Shortcut**.
- If the icon is missing, open Relay from Applications again.

### Commands fail with "permission denied"

- Enable **Requires Elevation** on commands that need `sudo`.
- For commands in protected directories, grant **Full Disk Access** in System Settings.

### Notifications are not appearing

- Grant notification permission in **System Settings → Notifications → Relay**.
- Make sure **Notify on Completion** is enabled on the command.

### "Relay cannot be opened because it is from an unidentified developer"

Right-click `Relay.app` in Finder and choose **Open**, then confirm in the dialog. See Step 5 above.

---

*© 2026 Siveesh Kodapully · [learnwithsk.com](https://learnwithsk.com)*
