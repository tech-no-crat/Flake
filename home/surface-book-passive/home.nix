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
  programs.git.enable = true;
  programs.git.settings = {
    user.name = "Tech-no-crat";
    user.email = "tech-no-crat2526@gmail.com";
  };
  # Allow unfree packages (just in case)
  nixpkgs.config.allowUnfree = true;

  home.stateVersion = "25.05";
}
