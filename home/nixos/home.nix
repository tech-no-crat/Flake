{ config, pkgs, pkgs-unstable, lib, ... }:

{
  imports = [ ../default/home.nix ];

  # Tell VS Code to use 1Password CLI for secret storage (works on both GNOME and Hyprland)
  home.file.".vscode/argv.json" = {
    force = true;
    text = builtins.toJSON {
      "password-store" = "1password";
    };
  };

  # Set the default 1Password account so `op` never prompts for account selection.
  # Picked up by systemd user session, so GUI apps (VSCode, etc.) inherit it.
  home.sessionVariables.OP_ACCOUNT = "dayam";

  # --- Desktop-specific packages ---
  home.packages = lib.mkAfter (with pkgs; [
    # Communication
    thunderbird

    # Network Tools
    ethtool
    iw

    # Development
    pkgs-unstable.discord
    pkgs-unstable.vscode

    # Hyprland utilities
    grim            # screenshot tool
    slurp           # region selector for screenshots
    pavucontrol     # audio GUI
    nautilus        # file manager
    playerctl       # media key support
    brightnessctl   # brightness control

    # Desktop shell extras
    wlogout         # power menu
    nwg-drawer      # GNOME-style app launcher grid
    nwg-look        # GTK theming / appearance settings
    blueman         # Bluetooth manager GUI
    baobab          # disk usage analyser
    networkmanagerapplet  # nm-connection-editor for network settings

    # Theming
    adw-gtk3              # Libadwaita-style GTK3 dark theme
    papirus-icon-theme    # icon theme with dark variant
    adwaita-qt            # Adwaita look for Qt5/Qt6 apps
    adwaita-qt6
  ]);

  # ---------------------------------------------------------------------------
  # Hyprland window manager
  # ---------------------------------------------------------------------------
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {

      monitor = [
        "DP-1, 2560x1440@144, 0x0, 1"
        "DP-2, 2560x1440@144, 2560x0, 1"
      ];

      # Run on session start
      exec-once = [
        "waybar"
        "dunst"
        # Export Hyprland env vars into the systemd user session so Sunshine
        # prep-cmd scripts can call hyprctl without manually setting the instance sig
        "systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS"
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland"
        # Pinned cheat sheet — bottom-right of DP-2, visible on all workspaces
        "kitty --class hypr-cheatsheet --hold -e cat /home/shyam/.config/hypr/cheatsheet.txt"
        "code"
        # Regenerate Sunshine app list (Desktop + Steam Big Picture + 10 recent games)
        # then restart Sunshine so it picks up the new apps.json immediately
        "bash -c 'sunshine-gen-apps && systemctl --user restart sunshine'"
      ];

      env = [
        "XCURSOR_SIZE,24"
        "QT_QPA_PLATFORM,wayland"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
        "GBM_BACKEND,amdgpu"
        "__GLX_VENDOR_LIBRARY_NAME,mesa"
      ];

      input = {
        kb_layout = "us";
        follow_mouse = 1;
        sensitivity = 0;
        accel_profile = "flat";
      };

      general = {
        gaps_in = 4;
        gaps_out = 8;
        border_size = 2;
        "col.active_border" = "rgba(88c0d0ff) rgba(81a1c1ff) 45deg";
        "col.inactive_border" = "rgba(4c566aff)";
        layout = "dwindle";
        allow_tearing = true; # Reduces input latency for games
      };

      decoration = {
        rounding = 8;
        blur = {
          enabled = true;
          size = 6;
          passes = 2;
        };
        shadow = {
          enabled = true;
          range = 8;
          render_power = 2;
          color = "rgba(1a1a1aee)";
        };
      };

      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
        vfr = true; # Variable frame rate — saves power when idle
      };

      # Workspaces 1-5 on DP-2 (right/primary), 6-9 on DP-1 (left)
      workspace = [
        "1, monitor:DP-2, default:true"
        "2, monitor:DP-2"
        "3, monitor:DP-2"
        "4, monitor:DP-2"
        "5, monitor:DP-2"
        "6, monitor:DP-1, default:true"
        "7, monitor:DP-1"
        "8, monitor:DP-1"
        "9, monitor:DP-1"
      ];

      # Keybindings — $mod = Super (Windows key)
      "$mod" = "SUPER";

      bind = [
        "$mod, Return, exec, kitty"
        "$mod, Q, killactive"
        "$mod SHIFT, E, exit"
        "$mod, E, exec, nautilus"
        "$mod, V, togglefloating"
        "$mod, F, fullscreen"
        "$mod, R, exec, rofi -show drun"
        "$mod SHIFT, L, exec, hyprlock"
        "$mod, P, exec, wlogout"
        "$mod SHIFT, A, exec, nwg-drawer"
        "$mod SHIFT, S, exec, ~/.local/bin/settings-hub"

        # Focus (arrow keys)
        "$mod, left,  movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up,    movefocus, u"
        "$mod, down,  movefocus, d"

        # Move windows
        "$mod SHIFT, left,  movewindow, l"
        "$mod SHIFT, right, movewindow, r"
        "$mod SHIFT, up,    movewindow, u"
        "$mod SHIFT, down,  movewindow, d"

        # Workspaces
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"

        # Move window to workspace
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"

        # Screenshots (saved to clipboard)
        ", Print,       exec, grim -g \"$(slurp)\" - | wl-copy"
        "SHIFT, Print,  exec, grim - | wl-copy"
      ];

      # Mouse bindings (hold $mod + drag)
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      # Repeatable bindings (volume / media keys)
      bindel = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute,        exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioPlay,        exec, playerctl play-pause"
        ", XF86AudioNext,        exec, playerctl next"
        ", XF86AudioPrev,        exec, playerctl previous"
      ];

    };

    # Window rules — Hyprland 0.54+ v3 block syntax
    extraConfig = ''
      windowrule {
        name = suppress-maximize
        match:class = .*
        suppress_event = maximize
      }

      windowrule {
        name = steam-float
        match:class = ^(steam)$
        match:title = ^(Steam)$
        float = true
      }

      windowrule {
        name = 1password-float
        match:class = ^(1Password)$
        float = true
      }

      windowrule {
        name = pavucontrol-float
        match:class = ^(pavucontrol)$
        float = true
      }

      windowrule {
        name = games-tearing
        match:class = ^(steam_app_.*)$
        immediate = true
      }

      windowrule {
        name = cheatsheet-float
        match:class = ^(hypr-cheatsheet)$
        float = true
        pin = true
        size = 460 560
        move = 4650 870
        no_focus = true
        no_blur = true
      }

      windowrule {
        name = wlogout-fullscreen
        match:class = ^(wlogout)$
        float = true
        fullscreen = true
        no_anim = true
      }

      windowrule {
        name = nwg-drawer-float
        match:class = ^(nwg-drawer)$
        float = true
        center = true
      }
    '';
  };

  # ---------------------------------------------------------------------------
  # Hyprland cheat sheet (pinned bottom-right window)
  # ---------------------------------------------------------------------------
  home.file.".config/hypr/cheatsheet.txt".text = ''
    ╔══════════════════════════════════════╗
    ║         HYPRLAND CHEAT SHEET         ║
    ╠══════════════════════════════════════╣
    ║ SUPER + Return     Terminal (kitty)  ║
    ║ SUPER + R          App launcher      ║
    ║ SUPER + Q          Close window      ║
    ║ SUPER + F          Fullscreen        ║
    ║ SUPER + V          Toggle float      ║
    ║ SUPER + E          File manager      ║
    ║ SUPER + Shift + L  Lock screen       ║
    ║ SUPER + Shift + E  Exit Hyprland     ║
    ║ SUPER + P          Power menu        ║
    ║ SUPER + Shift + A  App drawer        ║
    ║ SUPER + Shift + S  Settings hub      ║
    ╠══════════════════════════════════════╣
    ║ SUPER + 1-9        Switch workspace  ║
    ║ SUPER+Shift + 1-9  Move to workspace ║
    ╠══════════════════════════════════════╣
    ║ SUPER + arrows     Move focus        ║
    ║ SUPER+Shift+arrows Move window       ║
    ╠══════════════════════════════════════╣
    ║ SUPER + drag       Move window       ║
    ║ SUPER + RMB drag   Resize window     ║
    ╠══════════════════════════════════════╣
    ║ Print              Screenshot region ║
    ║ Shift + Print      Screenshot full   ║
    ╠══════════════════════════════════════╣
    ║ Workspaces 1-5  →  DP-2 (right)      ║
    ║ Workspaces 6-9  →  DP-1 (left)       ║
    ╚══════════════════════════════════════╝
  '';

  # ---------------------------------------------------------------------------
  # Terminal — kitty
  # ---------------------------------------------------------------------------
  programs.kitty = {
    enable = true;
    settings = {
      font_family = "JetBrainsMono Nerd Font";
      font_size = 12;
      background_opacity = "0.95";
      window_padding_width = 8;
      confirm_os_window_close = 0;
    };
  };

  # ---------------------------------------------------------------------------
  # App launcher — rofi (Wayland fork)
  # ---------------------------------------------------------------------------
  programs.rofi = {
    enable = true;
    extraConfig = {
      modi = "drun,run";
      icon-theme = "Papirus";
      show-icons = true;
      drun-display-format = "{name}";
      disable-history = false;
      hide-scrollbar = true;
      display-drun = "  Apps";
    };
    theme = "nord";
  };

  # Settings hub — rofi script that presents categorised settings launchers
  home.file.".local/bin/settings-hub" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      declare -A actions
      actions=(
        ["󰔄  Appearance (GTK)"]="nwg-look"
        ["󰕾  Audio"]="pavucontrol"
        ["󰂯  Bluetooth"]="blueman-manager"
        ["󰩟  Network"]="nm-connection-editor"
        ["󰋊  Disk Usage"]="baobab"
      )

      chosen=$(printf '%s\n' "''${!actions[@]}" | sort | \
        rofi -dmenu -i -p "  Settings" \
          -theme-str 'window {width: 420px;} listview {lines: 6;}')

      [[ -n "$chosen" ]] && ''${actions[$chosen]} &
    '';
  };

  # ---------------------------------------------------------------------------
  # Power menu — wlogout
  # ---------------------------------------------------------------------------
  home.file.".config/wlogout/layout".text = ''
    {
        "label" : "lock",
        "action" : "hyprlock",
        "text" : "Lock",
        "keybind" : "l"
    }
    {
        "label" : "logout",
        "action" : "hyprctl dispatch exit",
        "text" : "Logout",
        "keybind" : "e"
    }
    {
        "label" : "suspend",
        "action" : "systemctl suspend",
        "text" : "Suspend",
        "keybind" : "u"
    }
    {
        "label" : "reboot",
        "action" : "systemctl reboot",
        "text" : "Reboot",
        "keybind" : "r"
    }
    {
        "label" : "shutdown",
        "action" : "systemctl poweroff",
        "text" : "Shutdown",
        "keybind" : "s"
    }
  '';

  home.file.".config/wlogout/style.css".text = ''
    * {
      background-image: none;
      box-shadow: none;
    }
    window {
      background-color: rgba(18, 18, 28, 0.9);
    }
    button {
      color: #cdd6f4;
      background-color: rgba(30, 30, 46, 0.7);
      border-style: solid;
      border-width: 2px;
      border-color: rgba(137, 180, 250, 0.2);
      border-radius: 12px;
      background-repeat: no-repeat;
      background-position: center;
      background-size: 40%;
      font-size: 18px;
      font-weight: bold;
      margin: 20px;
    }
    button:focus, button:active, button:hover {
      background-color: rgba(137, 180, 250, 0.25);
      border-color: #89b4fa;
      outline-style: none;
    }
    #lock     { background-image: image(url("/run/current-system/sw/share/wlogout/icons/lock.png")); }
    #logout   { background-image: image(url("/run/current-system/sw/share/wlogout/icons/logout.png")); }
    #suspend  { background-image: image(url("/run/current-system/sw/share/wlogout/icons/suspend.png")); }
    #reboot   { background-image: image(url("/run/current-system/sw/share/wlogout/icons/reboot.png")); }
    #shutdown { background-image: image(url("/run/current-system/sw/share/wlogout/icons/shutdown.png")); }
  '';

  # ---------------------------------------------------------------------------
  # Status bar — Waybar (on DP-2 only)
  # ---------------------------------------------------------------------------
  programs.waybar = {
    enable = true;
    settings = [
      {
        layer = "top";
        position = "top";
        height = 32;
        output = "DP-2";
        modules-left   = [ "hyprland/workspaces" "hyprland/window" ];
        modules-center = [ "clock" ];
        modules-right  = [ "pulseaudio" "network" "cpu" "memory" "temperature" "tray" ];

        "hyprland/workspaces" = {
          format = "{id}";
          on-click = "activate";
          sort-by-number = true;
        };

        "hyprland/window" = {
          max-length = 60;
        };

        clock = {
          format = "{:%H:%M  %a %b %d}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        cpu = {
          format = " {usage}%";
          interval = 2;
          tooltip = false;
        };

        memory = {
          format = " {used:0.1f}G";
          interval = 5;
        };

        temperature = {
          critical-threshold = 85;
          format = " {temperatureC}°C";
          format-critical = " {temperatureC}°C";
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = "󰝟 muted";
          format-icons.default = [ "󰕿" "󰖀" "󰕾" ];
          on-click = "pavucontrol";
        };

        network = {
          format-ethernet     = "󰈀 {ipaddr}";
          format-wifi         = "󰤨 {signalStrength}%";
          format-disconnected = "󰤭 disconnected";
          tooltip-format      = "{essid}\n{ipaddr}/{cidr}";
        };

        tray.spacing = 8;
      }
    ];

    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font", "Font Awesome 6 Free";
        font-size: 13px;
        min-height: 0;
      }
      window#waybar {
        background-color: rgba(30, 30, 46, 0.92);
        border-bottom: 2px solid rgba(137, 180, 250, 0.3);
        color: #cdd6f4;
      }
      #workspaces button {
        padding: 2px 10px;
        color: #6c7086;
        background: transparent;
        border: none;
        border-radius: 4px;
        margin: 4px 2px;
      }
      #workspaces button:hover {
        background-color: rgba(137, 180, 250, 0.15);
        color: #cdd6f4;
      }
      #workspaces button.active {
        color: #89b4fa;
        background-color: rgba(137, 180, 250, 0.2);
      }
      #workspaces button.urgent {
        color: #f38ba8;
      }
      #window {
        padding: 0 12px;
        color: #a6adc8;
      }
      #clock {
        padding: 0 16px;
        color: #cdd6f4;
        font-weight: bold;
      }
      #cpu, #memory, #temperature, #pulseaudio, #network, #tray {
        padding: 0 12px;
        color: #cdd6f4;
      }
      #temperature.critical {
        color: #f38ba8;
      }
    '';
  };

  # ---------------------------------------------------------------------------
  # Notifications — dunst
  # ---------------------------------------------------------------------------
  services.dunst = {
    enable = true;
    settings = {
      global = {
        width         = 300;
        height        = 300;
        offset        = "10x42";
        origin        = "top-right";
        transparency  = 10;
        frame_color   = "#89b4fa";
        font          = "JetBrainsMono Nerd Font 11";
        corner_radius = 8;
      };
      urgency_low = {
        background = "#1e1e2e";
        foreground = "#cdd6f4";
        timeout    = 5;
      };
      urgency_normal = {
        background = "#1e1e2e";
        foreground = "#cdd6f4";
        timeout    = 8;
      };
      urgency_critical = {
        background  = "#1e1e2e";
        foreground  = "#f38ba8";
        frame_color = "#f38ba8";
        timeout     = 0;
      };
    };
  };

  # ---------------------------------------------------------------------------
  # Dark mode — GTK / Qt / cursor
  # ---------------------------------------------------------------------------

  # GTK3 — adw-gtk3-dark gives Libadwaita look to legacy GTK3 apps
  gtk = {
    enable = true;
    theme = {
      name    = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name    = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name = "Adwaita";
      size = 24;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
  };

  # dconf — tells GTK4 / libadwaita apps to use dark colour scheme system-wide
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    gtk-theme    = "adw-gtk3-dark";
    icon-theme   = "Papirus-Dark";
    cursor-theme = "Adwaita";
    cursor-size  = 24;
  };

  # Qt — match Adwaita dark so Qt apps (VLC, etc.) blend in
  qt = {
    enable = true;
    platformTheme.name = "adwaita";
    style = {
      name    = "adwaita-dark";
      package = pkgs.adwaita-qt;
    };
  };

  # Session-wide env vars — picked up by any XDG-aware launcher
  # Note: QT_QPA_PLATFORMTHEME is set automatically by qt.platformTheme
  home.sessionVariables = {
    GTK_THEME     = "adw-gtk3-dark";
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE  = "24";
  };
}
