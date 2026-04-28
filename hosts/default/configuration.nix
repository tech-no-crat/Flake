# hosts/default/configuration.nix
# Common configuration shared by all NixOS hosts: Nix settings, boot, hardware, networking,
# and core services. Module selection (gnome, audio, gaming, etc.) is declared in flake.nix
{ config, pkgs, ... }:

{
  # No imports here; all modules are declared in flake.nix per-configuration
  # This file is the consolidated baseline of system settings

  # --- Nix Settings ---
  nix.settings = {
    # Allows specified users to perform privileged Nix operations
    trusted-users = [ "root" "shyam" ];
    
    # Enable flakes and new nix command
    experimental-features = [ "nix-command" "flakes" ];
  };

  # --- Boot & Hardware ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10; # Keep last 10 generations in boot menu
  boot.loader.efi.canTouchEfiVariables = true;

  # Graphics - baseline (host-specific configs can add more)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # --- Networking ---
  networking.networkmanager.enable = true;
  
  # Firewall: Keep SSH & WoL open
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.firewall.allowedUDPPorts = [ 9 ];

  # --- Services ---
  services.openssh.enable = true;

  # GNOME Keyring — provides a libsecret daemon that runs independently of GNOME.
  # VS Code and other apps use it to persist secrets under Hyprland.
  # A keyring with an empty password auto-unlocks without needing PAM integration.
  services.gnome.gnome-keyring.enable = true;
  services.tailscale.enable = true;
  services.resolved.enable = true;
  networking.useNetworkd = false;

  # --- System Packages ---
  environment.systemPackages = with pkgs; [
    vim
    wget
  ];

  programs.firefox.enable = true;
  nixpkgs.config.allowUnfree = true;

  # --- Garbage Collection ---
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
}
