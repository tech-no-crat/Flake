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
    ../../modules/intel-surface.nix
    # Applications
    ../../modules/1password.nix
  ];

  # --- Surface-specific hardware ---
  networking.hostName = "surface-book-passive";
  hardware.microsoft-surface.kernelVersion = "stable";

  # Add display manager setup for autoLogin (surface-specific)
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "shyam";

  # Cache configuration (unique to this host)
  nix.settings.secret-key-files = [ "/home/shyam/.config/nix/secret-key" ];
  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypf7apZDa8T7nheRbMjGQB7QS0="
    "nixos:ja/7KdhK9zIWJCUM+FQCHNgUqNExRTNWSDXIkS++ohw="
    "nixos:fMkk4PAA/Ep6aEEL+zDT4Lv3jalYk0Yl+vJ2cho0+wL4DJElp7hCwOh0fVz5CRrqrVn+oIUZEuegMJSgn8wcDw=="
  ];
  nix.settings.require-sigs = false;

  system.stateVersion = "25.05";
}
