{ config, pkgs, pkgs-unstable, ... }:

{
  home.username = "shyam";
  home.homeDirectory = "/home/shyam";

  # --- User Packages ---
  home.packages = with pkgs; [
    # Communication / Sync
    nextcloud-client
    moonlight-qt
    
    # Productivity
    obsidian
    
    # Development / Tools
    neovim
    nodejs_24
    #n8n
    
    # CLI Tools
    _1password-cli 
  ];

  # Allow unfree packages (just in case)
  nixpkgs.config.allowUnfree = true;

  home.stateVersion = "25.05";
}
