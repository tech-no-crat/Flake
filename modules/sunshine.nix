{ config, pkgs, pkgs-unstable, ... }:

let
  # These scripts are called by Sunshine when a client connects/disconnects.
  # They use hyprctl to disable/re-enable the secondary monitor (DP-1) so
  # streaming fills the primary display (DP-2) cleanly.
  #
  # The HYPRLAND_INSTANCE_SIGNATURE is imported into the systemd user session
  # by Hyprland's exec-once, so Sunshine (a systemd user service) inherits it.
  # The XDG_RUNTIME_DIR fallback handles edge cases where it isn't set.
  monitorOff = pkgs.writeShellScript "sunshine-monitor-off" ''
    export XDG_RUNTIME_DIR="/run/user/$(id -u)"
    # Fallback: find the Hyprland instance signature if not already in env
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
in
{
  # 1. Force the service to use the unstable version
  services.sunshine = {
    enable = true;
    package = pkgs-unstable.sunshine; # This is the key line
    autoStart = true;
    capSysAdmin = true; # Required for keyboard/mouse/gamepad emulation
    openFirewall = true; # Automatically opens 47984, 47989, 47990, 48010 (TCP) & 47998-48000 (UDP)

    applications = {
      apps = [
        {
          name = "SteamBigPicture";
          detached = [ "setsid steam steam://open/bigpicture" ];
          auto-detach = true;
          image-path = "steam.png";
          prep-cmd = [
            {
              do = "${monitorOff}";
              undo = "${monitorOn}";
              elevated = false;
            }
          ];
        }
        {
          name = "Desktop";
          image-path = "desktop.png";
          prep-cmd = [
            {
              do = "${monitorOff}";
              undo = "${monitorOn}";
              elevated = false;
            }
          ];
        }
      ];
    };
  };

  # 2. Add the unstable package to your system environment for manual CLI access
  environment.systemPackages = [
    pkgs-unstable.sunshine
  ];

}

  # 3. Manual Firewall Rules (Only for your custom ranges)
  #networking.firewall = {
  #  allowedUDPPortRanges = [
  #    { from = 8000; to = 8010; }
  #  ];
  #};
  # AIGEN, don't know what this is
  # 4. Optional but Recommended: uinput rules for controllers
  # This ensures Sunshine has permission to create virtual input devices
  #boot.kernelModules = [ "uinput" ];
  #services.udev.extraRules = ''
  #  KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
  #'';
