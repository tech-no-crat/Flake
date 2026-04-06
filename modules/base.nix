# modules/base.nix
# Common configuration shared by all NixOS hosts
{ config, pkgs, ... }:

{
  # --- Boot & Hardware ---
  boot.loader.systemd-boot.enable = true;
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
