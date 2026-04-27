# 2026-04-26 — Hyprland Desktop Setup & Enhancements

**Host:** `nixos` (AMD Radeon RX 9070 XT, dual 2560×1440@144Hz DP-1/DP-2)  
**NixOS:** 26.05 (Yarara), kernel 7.0.0  
**Commits:** `03f1e6d` → `810180f`

---

## Summary

This session migrated the `nixos` desktop host from GNOME to Hyprland, resolved several
post-migration issues, and extended the setup with streaming integrations and desktop utilities.

---

## Changes

### 1. GNOME → Hyprland migration (`03f1e6d`)

**Files:** `modules/hyprland.nix` (new), `flake.nix`, `home/nixos/home.nix`

- Created `modules/hyprland.nix` as a drop-in replacement for `modules/gnome.nix`
  - `programs.hyprland` with XWayland enabled
  - `greetd` auto-login session launching `Hyprland` as user `shyam`
  - `xdg-desktop-portal-gtk` extra portal
  - JetBrains Mono Nerd Font + Font Awesome
- Replaced GNOME module with Hyprland module in `flake.nix` for `nixos` host
- Built full Home Manager Hyprland config in `home/nixos/home.nix`:
  - Dual monitor layout: DP-1 left (0×0), DP-2 right/primary (2560×0)
  - Workspaces 1–5 on DP-2, 6–9 on DP-1
  - Nord colour scheme, 8px rounding, blur, drop shadows
  - Waybar on DP-2 only (workspaces, clock, CPU, RAM, temp, audio, network, tray)
  - dunst notifications, kitty terminal, rofi launcher
  - Full keybinding set (Super+Return, Q, R, E, F, V, arrows, 1–9, screenshots)

### 2. Autologin fix (`ce21954`)

- Removed GDM workaround, enabled native greetd autologin for user `shyam`

### 3. Pinned cheatsheet window + windowrule deprecation fix (`0ff7245`)

**Files:** `home/nixos/home.nix`

- Replaced deprecated `windowrulev2` syntax with `windowrule` (Hyprland ≥0.41)
- Added pinned floating kitty window showing a keybinding reference card
  - Launched via `exec-once`, pinned to bottom-right of DP-2 via window rules
  - Content managed by `home.file.".config/hypr/cheatsheet.txt"`

### 4. VS Code auto-launch (`44c7bfc`)

- Added `code` to Hyprland `exec-once` so VS Code opens on every login

### 5. Hyprland 0.54 windowrule v3 migration (`16a257b`)

**Files:** `home/nixos/home.nix`

Hyprland 0.54 replaced the flat `windowrule=rule, class:.*` keyword syntax with a new
block/special-category format. All rules migrated to:

```
windowrule {
  name = <identifier>
  match:class = <regex>
  <property> = <value>
}
```

Rules migrated: `suppress-maximize`, `steam-float`, `1password-float`, `pavucontrol-float`,
`games-tearing`, `cheatsheet-float`.

### 6. Dynamic Sunshine app menu (`2a65a02`)

**Files:** `modules/sunshine.nix`, `home/nixos/home.nix`

- Replaced static `applications.apps` NixOS option with `sunshine-gen-apps` Python script
- Script reads all Steam `appmanifest_*.acf` files across all library roots, sorts by
  `LastPlayed`, and writes `~/.config/sunshine/apps.json` with:
  - **Desktop** — bare Hyprland desktop
  - **Steam Big Picture** — `steam -bigpicture`
  - **Top 10 recently played games** — launched via `steam://rungameid/<id>`, with Steam CDN
    cover art URLs
- All entries include DP-1 monitor disable/restore prep-cmds
- `settings.file_apps` pointed at `~/.config/sunshine/apps.json` (user-writable)
- Added `exec-once` entry: `bash -c 'sunshine-gen-apps && systemctl --user restart sunshine'`

### 7. Bluetooth + RNNoise noise cancellation (`b48262d`)

**Files:** `hosts/nixos/configuration.nix`, `modules/audio.nix`, `home/nixos/home.nix`

**Bluetooth:**
- `hardware.bluetooth.enable = true` + `hardware.bluetooth.powerOnBoot = true`
- `services.blueman.enable = true` (tray applet + `blueman-manager` GUI)

**Noise cancellation (Discord mic):**
- Added `jack.enable` and `alsa.support32Bit` to PipeWire
- Configured `pipewire.extraConfig.pipewire."99-noise-cancellation"` with a LADSPA
  filter-chain using `rnnoise-plugin` (`librnnoise_ladspa.so`)
- Exposes a virtual **"Noise Canceling source"** device; select it as mic input in Discord

### 8. Power menu, app drawer, settings hub (`810180f`)

**Files:** `home/nixos/home.nix`

| Tool | Keybind | Description |
|---|---|---|
| `wlogout` | `Super+P` | Full-screen power menu: lock / logout / suspend / reboot / shutdown |
| `nwg-drawer` | `Super+Shift+A` | GNOME-style categorised app icon grid |
| `settings-hub` | `Super+Shift+S` | rofi menu: Appearance, Audio, Bluetooth, Network, Disk Usage |

- `wlogout` configured with Nord-themed CSS (dark background, rounded buttons, icon artwork)
- `settings-hub` is a shell script in `~/.local/bin/` that maps display names to commands
  and pipes them through `rofi -dmenu`
- `rofi` configured with Nord theme, icons, `drun` mode
- New packages: `wlogout`, `nwg-drawer`, `nwg-look`, `baobab`, `networkmanagerapplet`, `blueman`

### 9. Ongoing windowrule fixes

| Commit | Fix |
|---|---|
| `0ff7245` | `windowrulev2` → `windowrule` (0.41 deprecation) |
| `16a257b` | Flat keyword → v3 block syntax (0.54 breaking change) |
| This session | `noanim` → `no_anim` (correct field name in v3 syntax) |

---

## Current Keybindings

| Keybind | Action |
|---|---|
| `Super+Return` | Terminal (kitty) |
| `Super+R` | App search (rofi drun) |
| `Super+Shift+A` | App drawer (nwg-drawer) |
| `Super+Shift+S` | Settings hub |
| `Super+P` | Power menu (wlogout) |
| `Super+Q` | Close window |
| `Super+F` | Fullscreen |
| `Super+V` | Toggle float |
| `Super+E` | Files (Nautilus) |
| `Super+Shift+L` | Lock (hyprlock) |
| `Super+Shift+E` | Exit Hyprland |
| `Super+1–9` | Switch workspace |
| `Super+Shift+1–9` | Move window to workspace |
| `Super+arrows` | Move focus |
| `Super+Shift+arrows` | Move window |
| `Super+drag` | Move window (mouse) |
| `Super+RMB drag` | Resize window (mouse) |
| `Print` | Screenshot region → clipboard |
| `Shift+Print` | Screenshot full → clipboard |
