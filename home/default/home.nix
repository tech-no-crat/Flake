{ config, pkgs, pkgs-unstable, ... }:

{
  home.username = "shyam";
  home.homeDirectory = "/home/shyam";
  
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # --- Shared User Packages ---
  home.packages = with pkgs; [
    # Communication / Sync
    nextcloud-client
    
    # Productivity
    obsidian
    thunderbird
    
    # Development / Tools
    git
    ethtool
    iw
    neovim
    
    # Unstable packages
    pkgs-unstable.discord
    pkgs-unstable.vscode
  ];

  # --- Programs ---
  programs.direnv.enable = true;
  programs.git.enable = true;
  programs.git.settings = {
    user.name = "Tech-no-crat";
    user.email = "tech-no-crat2526@gmail.com";
  };

  home.stateVersion = "25.05";
}
