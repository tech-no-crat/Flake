{ config, pkgs, pkgs-unstable, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../default/configuration.nix
  ];

  # --- Surface-specific hardware ---
  networking.hostName = "surface-book-active";
  hardware.microsoft-surface.kernelVersion = "stable";

  # Add display manager setup for autoLogin (surface-specific)
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "shyam";

  system.stateVersion = "25.05";
}
