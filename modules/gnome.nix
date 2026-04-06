# modules/gnome.nix
# GNOME desktop environment configuration
{ config, pkgs, ... }:

{
  # --- Desktop ---
  services.xserver = {
    enable = true;
    xkb.layout = "us";
    xkb.variant = "";
  };

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # --- Audio & Printing ---
  services.printing.enable = true;
  services.printing.drivers = [
    pkgs.splix
    pkgs.samsung-unified-linux-driver
  ];

  # --- User Setup ---
  users.users.shyam = {
    isNormalUser = true;
    description = "shyam";
    extraGroups = [ "networkmanager" "wheel" "uinput" "input" "video" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINmAV4/B3jWOIJPgexSzCDDcK1lb+fD2tzA0i+Lxxgs3 shyam@clerics.ca"
    ];
  };
}

