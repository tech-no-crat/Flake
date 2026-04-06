{ config, pkgs, pkgs-unstable, ... }:

{
  imports = [
    ./hardware-configuration.nix
    # Common configuration from default
    ../default/configuration.nix
    # Audio (laptop version with 32-bit support)
    ../../modules/audio-laptop.nix
    # Surface-specific
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
