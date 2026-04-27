# modules/hyprland.nix
# Hyprland Wayland compositor — system-level config for the nixos desktop host
{ config, pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Autologin directly into Hyprland — no greeter needed
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${config.programs.hyprland.package}/bin/start-hyprland";
      user = "shyam";
    };
  };

  # GTK portal for file pickers (hyprland portal for screensharing comes via programs.hyprland)
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # Fonts (Waybar icons + terminal)
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    font-awesome
  ];

  # System-wide Wayland utilities
  environment.systemPackages = with pkgs; [
    xdg-utils
    wl-clipboard
  ];

  # --- Carried over from gnome.nix ---

  services.printing.enable = true;
  services.printing.drivers = with pkgs; [
    splix
    samsung-unified-linux-driver
  ];

  users.users.shyam = {
    isNormalUser = true;
    description = "shyam";
    extraGroups = [ "networkmanager" "wheel" "uinput" "input" "video" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINmAV4/B3jWOIJPgexSzCDDcK1lb+fD2tzA0i+Lxxgs3 shyam@clerics.ca"
    ];
  };
}
