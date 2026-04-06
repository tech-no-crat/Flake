{ config, pkgs, pkgs-unstable, ... }:

{
  imports = [
    ./hardware-configuration.nix
    # Shared modules
    ../../modules/nix-settings.nix
    ../../modules/base.nix
    ../../modules/gnome.nix
    ../../modules/audio-laptop.nix
    ../../modules/surface-common.nix
    # GPU-specific
    ../../modules/nvidia-surface.nix
    # Applications
    ../../modules/1password.nix
  ];

  # --- Surface-specific hardware ---
  networking.hostName = "surface-book-active";
  hardware.microsoft-surface.kernelVersion = "stable";

  # Add display manager setup for autoLogin (surface-specific)
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "shyam";

  system.stateVersion = "25.05";
}
