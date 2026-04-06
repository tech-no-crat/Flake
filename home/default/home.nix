{ config, pkgs, pkgs-unstable, ... }:

{
  home.username = "shyam";
  home.homeDirectory = "/home/shyam";
  
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Suppress Home Manager version check (25.11 on Nixpkgs 26.05 works fine)
  home.enableNixpkgsReleaseCheck = false;

  # --- Common User Packages (shared across all hosts) ---
  home.packages = with pkgs; [
    # Communication / Sync
    nextcloud-client
    firefox
    
    # Productivity
    obsidian
    
    # Development / Tools
    git
    neovim
  ];

  # --- Programs (common to all) ---
  programs.direnv.enable = true;
  
  programs.git.enable = true;
  programs.git.settings = {
    user.name = "Tech-no-crat";
    user.email = "tech-no-crat2526@gmail.com";
  };

  home.stateVersion = "25.05";
}
