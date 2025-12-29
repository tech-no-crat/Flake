{ config, pkgs, pkgs-unstable, ... }:

{
  home.username = "shyam";
  home.homeDirectory = "/home/shyam";

  # --- User Packages ---
  home.packages = [
    pkgs.nextcloud-client
    pkgs.moonlight-qt
    pkgs.obsidian
    pkgs.neovim
    pkgs.nodejs_24
    pkgs._1password-cli
    
    # Explicitly from unstable
    pkgs-unstable.heroic-launcher
  ];
  # Allow unfree packages (just in case)
  nixpkgs.config.allowUnfree = true;

  home.stateVersion = "25.05";
}
