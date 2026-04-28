# modules/sunshine.nix
# Sunshine game-streaming host (Moonlight server) plus the gen-apps helper that
# rebuilds Sunshine's apps.json from the Steam library on login.
{ config, pkgs, pkgs-unstable, ... }:

let
  # ---------------------------------------------------------------------------
  # Monitor switching scripts — called by Sunshine prep-cmd on connect/disconnect
  # ---------------------------------------------------------------------------
  monitorOff = pkgs.writeShellScript "sunshine-monitor-off" ''
    export XDG_RUNTIME_DIR="/run/user/$(id -u)"
    if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
      HYPRLAND_INSTANCE_SIGNATURE=$(ls "$XDG_RUNTIME_DIR/hypr" 2>/dev/null | head -1)
    fi
    [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ] && exit 0
    export HYPRLAND_INSTANCE_SIGNATURE
    ${pkgs.hyprland}/bin/hyprctl keyword monitor "DP-1,disable"
  '';

  monitorOn = pkgs.writeShellScript "sunshine-monitor-on" ''
    export XDG_RUNTIME_DIR="/run/user/$(id -u)"
    if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
      HYPRLAND_INSTANCE_SIGNATURE=$(ls "$XDG_RUNTIME_DIR/hypr" 2>/dev/null | head -1)
    fi
    [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ] && exit 0
    export HYPRLAND_INSTANCE_SIGNATURE
    ${pkgs.hyprland}/bin/hyprctl keyword monitor "DP-1,2560x1440@144,0x0,1"
  '';

  # ---------------------------------------------------------------------------
  # sunshine-gen-apps: regenerates ~/.config/sunshine/apps.json at login.
  # Includes fixed entries (Desktop, Steam Big Picture) plus the 10 most
  # recently played Steam games, all wired up with the monitor prep-cmds.
  # ---------------------------------------------------------------------------
  genAppsScript = pkgs.writeScriptBin "sunshine-gen-apps" ''
    #!${pkgs.python3}/bin/python3
    import os, json, glob, re, sys
    from pathlib import Path

    HOME       = Path.home()
    STEAM_DIR  = HOME / ".local/share/Steam"
    APPS_JSON  = HOME / ".config/sunshine/apps.json"
    MONITOR_OFF = "${monitorOff}"
    MONITOR_ON  = "${monitorOn}"

    prep_cmd = [{"do": MONITOR_OFF, "undo": MONITOR_ON, "elevated": False}]

    # ---- Parse a Steam .acf manifest for appid / name / LastPlayed ----------
    def parse_acf(path):
        data = {}
        try:
            with open(path, "r", errors="replace") as f:
                for line in f:
                    for key in ("appid", "name", "LastPlayed"):
                        m = re.search(r'"' + key + r'"\s+"([^"]+)"', line, re.IGNORECASE)
                        if m:
                            data[key] = m.group(1)
        except OSError:
            pass
        return data

    # ---- Collect all Steam library roots -------------------------------------
    def steam_library_roots():
        roots = [STEAM_DIR / "steamapps"]
        lib_vdf = STEAM_DIR / "steamapps/libraryfolders.vdf"
        if lib_vdf.exists():
            for m in re.finditer(r'"path"\s+"([^"]+)"', lib_vdf.read_text(errors="replace")):
                p = Path(m.group(1)) / "steamapps"
                if p.is_dir():
                    roots.append(p)
        return roots

    # ---- Get top N recently played games ------------------------------------
    def recent_games(n=10):
        games = {}
        for root in steam_library_roots():
            for manifest in root.glob("appmanifest_*.acf"):
                d = parse_acf(manifest)
                lp = int(d.get("LastPlayed", 0))
                appid = d.get("appid")
                if lp > 0 and appid and "name" in d:
                    # Keep only the entry with the highest LastPlayed per appid
                    if appid not in games or lp > games[appid]["last_played"]:
                        games[appid] = {"appid": appid, "name": d["name"], "last_played": lp}
        return sorted(games.values(), key=lambda g: g["last_played"], reverse=True)[:n]

    # ---- Build app list -----------------------------------------------------
    apps = [
        {
            "name": "Desktop",
            "image-path": "desktop.png",
            "prep-cmd": prep_cmd,
        },
        {
            "name": "Steam Big Picture",
            "detached": ["steam -bigpicture"],
            "auto-detach": True,
            "image-path": "steam.png",
            "prep-cmd": prep_cmd,
        },
    ]

    for g in recent_games():
        apps.append({
            "name": g["name"],
            "detached": [f"steam steam://rungameid/{g['appid']}"],
            "auto-detach": True,
            "image-path": f"https://cdn.akamai.steamstatic.com/steam/apps/{g['appid']}/header.jpg",
            "prep-cmd": prep_cmd,
        })

    APPS_JSON.parent.mkdir(parents=True, exist_ok=True)
    APPS_JSON.write_text(json.dumps({"env": {}, "apps": apps}, indent=2))
    print(f"sunshine-gen-apps: wrote {len(apps)} apps to {APPS_JSON}", flush=True)
  '';
in
{
  services.sunshine = {
    enable = true;
    package = pkgs-unstable.sunshine;
    # autoStart disabled — Hyprland exec-once generates apps.json first,
    # then starts Sunshine so it always has the full app list on first boot.
    autoStart = false;
    capSysAdmin = true;
    openFirewall = true;

    # Point Sunshine at a user-writable path so sunshine-gen-apps can update
    # it at login without requiring a NixOS rebuild.
    settings.file_apps = "/home/shyam/.config/sunshine/apps.json";
  };

  environment.systemPackages = [
    pkgs-unstable.sunshine
    genAppsScript
  ];
}
