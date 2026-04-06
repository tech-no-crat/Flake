# modules/surface-common.nix
# Shared Surface-specific configuration (abstracted from gnome/base duplicates)
{ pkgs, ... }:

{
  # --- Localization (Surface-specific timezone and locales) ---
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # --- User Setup (Extend the gnome.nix user with Surface-specific groups) ---
  users.users.shyam = {
    extraGroups = [ "surface-control" ];
  };
}

