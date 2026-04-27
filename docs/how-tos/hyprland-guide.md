# Hyprland Guide — Windows User Reference

> Everything you used to do on Windows, and how to do it here.
> Keybindings below reflect the config in `home/nixos/home.nix`.
> **$mod = Super (the Windows key)**

---

## Table of Contents

1. [Launching Apps](#1-launching-apps)
2. [Window Management](#2-window-management)
3. [Workspaces (Virtual Desktops)](#3-workspaces-virtual-desktops)
4. [Moving Windows Between Workspaces](#4-moving-windows-between-workspaces)
5. [Floating Windows](#5-floating-windows)
6. [Screenshots](#6-screenshots)
7. [Power / Session Management](#7-power--session-management)
8. [File Manager](#8-file-manager)
9. [Settings & System Configuration](#9-settings--system-configuration)
10. [Audio & Volume](#10-audio--volume)
11. [Bluetooth](#11-bluetooth)
12. [Networking](#12-networking)
13. [Notifications](#13-notifications)
14. [Clipboard](#14-clipboard)
15. [Task Switcher / App Switcher](#15-task-switcher--app-switcher)
16. [Taskbar / System Tray](#16-taskbar--system-tray)
17. [Locking the Screen](#17-locking-the-screen)
18. [Multi-Monitor Setup](#18-multi-monitor-setup)
19. [Default Apps & File Associations](#19-default-apps--file-associations)
20. [Autostart Apps](#20-autostart-apps)
21. [Keyboard Shortcuts Reference Card](#21-keyboard-shortcuts-reference-card)

---

## 1. Launching Apps

### Windows Equivalent
- `Win` / `Win+S` — Start menu search
- `Win+R` — Run dialog

### Hyprland
| Action | Shortcut |
|---|---|
| App launcher (like Start menu search) | `Super + R` |
| Open terminal | `Super + Enter` |
| App grid (icon grid like Start menu tiles) | `Super + Shift + A` |

**Rofi** is the launcher. Type an app name and press Enter. It searches installed
applications, so `Super + R` → type "firefox" → Enter launches Firefox.

```
Example:
Super + R → type "vlc" → Enter        # open VLC
Super + R → type "settings" → Enter   # open GNOME Settings
```

> **Tip:** nwg-drawer (`Super + Shift + A`) shows a visual icon grid similar to
> the Windows Start screen — good when you can't remember an app name.

---

## 2. Window Management

### Tiling vs. Floating

Hyprland is a **tiling** compositor by default. New windows are automatically
arranged side-by-side so they fill the screen without overlapping. This is
different from Windows where windows float freely.

### Windows Equivalent
- `Win + ←/→` — Snap window to half screen
- `Win + ↑` — Maximize
- Drag title bar to rearrange

### Hyprland
| Action | Shortcut |
|---|---|
| Move focus left/right/up/down | `Super + Arrow keys` |
| Move window left/right/up/down | `Super + Shift + Arrow keys` |
| Toggle floating (free-move) for current window | `Super + V` |
| Fullscreen current window | `Super + F` |
| Close / kill window | `Super + Q` |

**Mouse actions (works in tiling AND floating):**
| Action | Mouse |
|---|---|
| Move a floating window | `Super + Left-click drag` |
| Resize any window | `Super + Right-click drag` |
| Focus a window | Click anywhere on it |

### Tiling Explained

When you open two terminals, they sit side by side. Open a third — it splits
a pane again. The layout is **dwindle** (binary space partitioning):

```
┌──────────┬──────────┐     ┌───────┬────┬────┐
│          │          │     │       │    │ C  │
│  Term A  │  Term B  │  →  │   A   │ B  ├────┤
│          │          │     │       │    │ D  │
└──────────┴──────────┘     └───────┴────┴────┘
   2 windows                    4 windows
```

To escape tiling for one window, press `Super + V` to make it float.

---

## 3. Workspaces (Virtual Desktops)

### Windows Equivalent
- `Win + Tab` → "Task View" → "+ New desktop"
- `Win + Ctrl + ←/→` — Switch virtual desktop

### Hyprland

There are **9 workspaces**. Workspaces 1–5 live on **DP-2** (right/primary
monitor). Workspaces 6–9 live on **DP-1** (left monitor).

| Action | Shortcut |
|---|---|
| Switch to workspace N | `Super + N` (where N is 1–9) |
| Switch to next workspace | `Super + Mouse scroll up` |
| Switch to previous workspace | `Super + Mouse scroll down` |

```
Example:
Super + 1   # go to workspace 1 (right monitor, first desktop)
Super + 6   # go to workspace 6 (left monitor, first desktop)
Super + 3   # go to workspace 3
```

**Think of it like this:**
- Workspaces 1–5 = 5 virtual desktops on your right screen
- Workspaces 6–9 = 4 virtual desktops on your left screen
- Each monitor has its own independent workspace stack

---

## 4. Moving Windows Between Workspaces

### Windows Equivalent
- `Win + Shift + ←/→` — Move window to adjacent virtual desktop
- Drag window thumbnail in Task View

### Hyprland
| Action | Shortcut |
|---|---|
| Move current window to workspace N | `Super + Shift + N` |
| Move window to workspace (stay on current) | `Super + Shift + N` |

```
Example:
Super + Shift + 3   # move focused window to workspace 3
Super + Shift + 6   # move it to workspace 6 (left monitor)
```

To move a window to another monitor's workspace, use the workspace number for
that monitor (6–9 for left monitor).

---

## 5. Floating Windows

Some windows automatically float (1Password, pavucontrol, Steam, etc.). You can
float/unfloat any window manually.

| Action | Shortcut |
|---|---|
| Toggle floating on focused window | `Super + V` |
| Move floating window | `Super + Left-click drag` |
| Resize floating window | `Super + Right-click drag` |

**Windows that auto-float in this config:**
- 1Password (credential popups)
- pavucontrol (audio mixer)
- Steam (main client window)
- wlogout (power menu)
- nwg-drawer (app launcher grid)
- The cheatsheet kitty terminal

---

## 6. Screenshots

### Windows Equivalent
- `Print Screen` — Copy full screen to clipboard
- `Win + Shift + S` — Snipping Tool / region select

### Hyprland
| Action | Shortcut |
|---|---|
| Capture a region (click-and-drag to select) | `Print Screen` |
| Capture entire screen | `Shift + Print Screen` |

Both shortcuts copy the image **directly to the clipboard** — paste into
Discord, GIMP, browser, etc. with `Ctrl + V`.

To save to a file instead:
```bash
# Save region to ~/Pictures
grim -g "$(slurp)" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png

# Save full screen
grim ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png
```

---

## 7. Power / Session Management

### Windows Equivalent
- `Win + X` → Shut down / Restart / Sleep
- Start menu → Power button

### Hyprland
| Action | Shortcut |
|---|---|
| Open power menu | `Super + P` |

The **wlogout** power menu shows 5 buttons:
- Lock
- Logout
- Suspend (sleep)
- Hibernate
- Reboot
- Shutdown

Click a button or press its highlighted letter.

**From the terminal:**
```bash
systemctl poweroff       # shut down
systemctl reboot         # restart
systemctl suspend        # sleep
systemctl hibernate      # hibernate
loginctl terminate-user $USER   # log out
```

---

## 8. File Manager

### Windows Equivalent
- `Win + E` — Open File Explorer

### Hyprland
| Action | Shortcut |
|---|---|
| Open file manager (Nautilus) | `Super + E` |

Nautilus is the GNOME Files app — works similarly to File Explorer.

**Keyboard shortcuts inside Nautilus:**
| Action | Shortcut |
|---|---|
| New folder | `Ctrl + Shift + N` |
| Open in terminal | Right-click → "Open in Terminal" |
| Toggle hidden files | `Ctrl + H` |
| Search | `Ctrl + F` |
| Back | `Alt + ←` |

**From the terminal (command line):**
```bash
ls -la              # list files (like dir /a)
cp file dest        # copy
mv file dest        # move / rename
rm file             # delete
rm -rf folder/      # delete folder recursively
mkdir newdir        # create directory
```

---

## 9. Settings & System Configuration

### Windows Equivalent
- `Win + I` — Windows Settings
- Control Panel

### Hyprland
| Action | Shortcut |
|---|---|
| Settings hub (curated rofi menu) | `Super + Shift + S` |

The settings hub opens a Rofi menu with quick-launch entries for:
- Display (GNOME Settings)
- Audio (pavucontrol)
- Bluetooth (blueman)
- Network (nm-connection-editor)
- Appearance (nwg-look)
- Printers
- Date & Time

**Individual tools:**
```bash
pavucontrol          # audio mixer (like Volume Mixer)
blueman-manager      # Bluetooth devices
nm-connection-editor # network connections (like Network & Internet Settings)
nwg-look             # GTK theme, fonts, icons (like Personalization)
gnome-control-center # full GNOME settings panel
```

---

## 10. Audio & Volume

### Windows Equivalent
- Volume icon in system tray → click/right-click
- Right-click speaker → "Open Volume Mixer"

### Hyprland

The Waybar status bar shows a volume indicator. **Right-click** it to open
pavucontrol (the full mixer).

**Keyboard:**
| Action | Key |
|---|---|
| Volume up | `XF86AudioRaiseVolume` (media key on keyboard) |
| Volume down | `XF86AudioLowerVolume` |
| Mute/unmute | `XF86AudioMute` |

From terminal:
```bash
wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%+    # volume up 10%
wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%-    # volume down 10%
wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle    # mute
wpctl status                                   # show all audio devices
```

**Noise cancellation:** A virtual microphone called "Noise Canceling source"
is available in pavucontrol input devices. Select it in any app (Discord, etc.)
to filter background noise via RNNoise.

---

## 11. Bluetooth

### Windows Equivalent
- Settings → Bluetooth & devices
- System tray Bluetooth icon

### Hyprland

Open **Blueman** from the settings hub or:
```bash
blueman-manager
```

Or via CLI:
```bash
bluetoothctl                    # interactive Bluetooth CLI
bluetoothctl scan on            # scan for devices
bluetoothctl pair XX:XX:XX:XX   # pair a device
bluetoothctl connect XX:XX:XX   # connect
bluetoothctl devices            # list known devices
```

---

## 12. Networking

### Windows Equivalent
- System tray network icon
- Settings → Network & Internet

### Hyprland

NetworkManager manages connections. The `nm-applet` tray icon appears in Waybar.

```bash
nm-connection-editor    # GUI for all connections (like Network Settings)
nmtui                   # terminal UI (ncurses) — good for SSH sessions
nmcli device wifi list  # list Wi-Fi networks
nmcli device wifi connect "SSID" password "pass"  # connect to Wi-Fi
nmcli connection show   # show all saved connections
```

**Tailscale** (if used):
```bash
sudo tailscale up       # connect
sudo tailscale down     # disconnect
tailscale status        # show peers
```

---

## 13. Notifications

### Windows Equivalent
- Toast notifications in bottom-right corner
- Action Center (`Win + A`)

### Hyprland

**Dunst** handles notifications. They appear top-right by default.

| Action | How |
|---|---|
| Dismiss a notification | Left-click it |
| Dismiss all | Middle-click any notification |
| See notification history | `dunstctl history-pop` (re-shows last notification) |

From terminal:
```bash
dunstctl close          # close top notification
dunstctl close-all      # close all
dunstctl history-pop    # show last dismissed notification
notify-send "Title" "Message"  # send a test notification
```

---

## 14. Clipboard

### Windows Equivalent
- `Ctrl + C` / `Ctrl + V`
- `Win + V` — Clipboard history

### Hyprland

Standard `Ctrl + C` / `Ctrl + V` works everywhere. For clipboard history,
install and configure `cliphist`:

```bash
# View clipboard history (add to config to set up properly)
cliphist list | rofi -dmenu | cliphist decode | wl-copy
```

> **Note:** A clipboard manager isn't configured by default yet. Screenshots
> go directly to clipboard via `wl-copy`.

**Wayland clipboard tools:**
```bash
wl-copy < file.txt          # copy file contents to clipboard
wl-paste                    # print clipboard contents
wl-paste > output.txt       # save clipboard to file
echo "hello" | wl-copy      # copy from stdin
```

---

## 15. Task Switcher / App Switcher

### Windows Equivalent
- `Alt + Tab` — Switch between windows
- `Win + Tab` — Task View

### Hyprland

By default, `Alt + Tab` is not configured (Hyprland doesn't have a built-in
task switcher). Use workspaces and focus shortcuts instead:

| Action | Shortcut |
|---|---|
| Focus next window | `Super + Arrow key` |
| Focus window by clicking | Click any visible window |

For an `Alt + Tab` style switcher, you can add `hyprswitch` or `rofi -show window`:
```bash
rofi -show window    # shows all open windows across workspaces
```

To add `Alt + Tab` to keybinds in `home.nix`:
```nix
"ALT, Tab, exec, rofi -show window"
```

---

## 16. Taskbar / System Tray

### Windows Equivalent
- Taskbar at bottom with pinned apps, running apps, and system tray

### Hyprland

**Waybar** is the status bar (top of screen by default in this config). It shows:
- Workspaces (click to switch)
- Active window title
- System tray (network, volume, Bluetooth, etc.)
- Clock

**Clicking Waybar elements:**
| Element | Left-click | Right-click |
|---|---|---|
| Volume | (none) | Opens pavucontrol |
| Workspace number | Switch to workspace | — |
| Clock | — | — |

To add a pinned app launcher to Waybar, edit the Waybar config in `home.nix`.

---

## 17. Locking the Screen

### Windows Equivalent
- `Win + L` — Lock screen

### Hyprland
| Action | Shortcut |
|---|---|
| Lock screen | `Super + Shift + L` |

**Hyprlock** is the screen locker — shows a minimal lock screen with a
password prompt.

Auto-lock after idle (if configured):
```bash
hypridle    # daemon that triggers lock after X minutes of inactivity
```

---

## 18. Multi-Monitor Setup

### Windows Equivalent
- `Win + P` — Display projection modes
- Settings → System → Display

### Hyprland

Monitors are configured in `home/nixos/home.nix`:
```nix
monitor = [
  "DP-1, 2560x1440@144, 0x0, 1"     # left monitor
  "DP-2, 2560x1440@144, 2560x0, 1"  # right/primary monitor
];
```

**Format:** `name, resolution@refresh, position_x x position_y, scale`

To detect monitor names:
```bash
hyprctl monitors         # list all connected monitors with names
wlr-randr                # alternative display info tool
```

To temporarily change a monitor setting without editing nix:
```bash
hyprctl keyword monitor DP-1,disable          # disable a monitor
hyprctl keyword monitor DP-1,2560x1440@144,0x0,1  # re-enable
```

**Moving focus between monitors:**
- Workspaces 1–5 are on DP-2 (right). Workspaces 6–9 are on DP-1 (left).
- `Super + 6` jumps focus to the left monitor (workspace 6).
- Move a window to the other monitor: `Super + Shift + 6` (sends to left).

---

## 19. Default Apps & File Associations

### Windows Equivalent
- Settings → Apps → Default Apps
- Right-click file → "Open with" → "Choose another app" → "Always use this app"

### Hyprland (Linux / XDG)

```bash
# Set default app for a MIME type
xdg-mime default firefox.desktop text/html
xdg-mime default org.gnome.Nautilus.desktop inode/directory

# Check current default
xdg-mime query default text/html

# Open a file with its default app (like double-clicking)
xdg-open file.pdf
xdg-open https://example.com

# Right-click → Open With in Nautilus works too
```

Common MIME types:
| File type | MIME type |
|---|---|
| Web pages | `text/html` |
| PDFs | `application/pdf` |
| Images (JPEG) | `image/jpeg` |
| Folders | `inode/directory` |
| Videos (MP4) | `video/mp4` |
| Music (MP3) | `audio/mpeg` |

---

## 20. Autostart Apps

### Windows Equivalent
- Task Manager → Startup tab
- `shell:startup` folder

### Hyprland

Edit `exec-once` in `home/nixos/home.nix`:

```nix
exec-once = [
  "waybar"
  "dunst"
  "code"           # VS Code
  # Add your apps here:
  "telegram-desktop"
  "firefox"
];
```

After editing, rebuild:
```bash
cd ~/Flakes
sudo nixos-rebuild switch --flake .#nixos
```

To run something once on every Hyprland **start** (including after lock):
use `exec-once`. To run every time a workspace is created, there is no direct
equivalent — use a systemd user service instead.

---

## 21. Keyboard Shortcuts Reference Card

> Also visible as the pinned cheatsheet terminal on your desktop (bottom-right).

### Window Management
| Shortcut | Action |
|---|---|
| `Super + Return` | Open terminal (kitty) |
| `Super + Q` | Close window |
| `Super + V` | Toggle floating |
| `Super + F` | Fullscreen |
| `Super + Shift + E` | Exit Hyprland |

### Focus & Movement
| Shortcut | Action |
|---|---|
| `Super + ←/→/↑/↓` | Move focus |
| `Super + Shift + ←/→/↑/↓` | Move window |
| `Super + Left-click drag` | Move floating window |
| `Super + Right-click drag` | Resize window |

### Workspaces
| Shortcut | Action |
|---|---|
| `Super + 1–9` | Switch to workspace |
| `Super + Shift + 1–9` | Move window to workspace |
| `Super + Scroll` | Cycle workspaces |

### Apps & Launchers
| Shortcut | Action |
|---|---|
| `Super + R` | App launcher (Rofi) |
| `Super + E` | File manager (Nautilus) |
| `Super + Shift + A` | App drawer grid (nwg-drawer) |
| `Super + Shift + S` | Settings hub |

### System
| Shortcut | Action |
|---|---|
| `Super + P` | Power menu (wlogout) |
| `Super + Shift + L` | Lock screen (hyprlock) |
| `Print Screen` | Screenshot region → clipboard |
| `Shift + Print Screen` | Screenshot full screen → clipboard |

---

## Tips & Tricks

### Quickly open a terminal anywhere
`Super + Enter` always opens a new terminal regardless of what's focused.

### Scratch / scratch-pad terminal
Open kitty normally, then `Super + V` to float it, resize with `Super + right-drag`.

### Run a one-off command without opening a full terminal
```
Super + R → type the command name (e.g. "pavucontrol")
```
Rofi can launch binaries directly, not just `.desktop` entries.

### Check what's eating resources (Task Manager equivalent)
```bash
btop     # excellent terminal system monitor (like Task Manager)
htop     # simpler alternative
```

### Find where a package installs a file
```bash
which firefox           # path to executable
nix-store -qR $(which firefox)   # all runtime dependencies
```

### App crashed / won't close
```bash
hyprctl clients         # list all windows with class names
hyprctl kill            # interactive click-to-kill
kill $(pgrep appname)   # kill by process name
```

### See Hyprland logs for debugging
```bash
journalctl --user -u greetd -f          # greetd startup logs
cat ~/.local/share/hyprland/hyprland.log  # Hyprland session log
hyprctl version                           # Hyprland version info
```
