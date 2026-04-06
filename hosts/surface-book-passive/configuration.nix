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
  # For passive deployment targets, allow unsigned paths from trusted nixos-rebuild deployments
  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypf7apZDa8T7nheRbMjGQB7QS0="
  ];
  nix.settings.require-sigs = false;
  # Allow importing from derivations for remote deployments
  nix.settings.allow-import-from-derivation = true;

  system.stateVersion = "25.05";
}
