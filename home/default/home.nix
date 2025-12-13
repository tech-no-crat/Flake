{ config, pkgs, pkgs-unstable, ... }:

{
  # Basic User Info
  home.username = "shyam";
  home.homeDirectory = "/home/shyam";
  # Allow unfree packages in Home Manager context
  nixpkgs.config.allowUnfree = true;
  
  # --- User Packages (The "Apps") ---
  home.packages = with pkgs; [
    # Communication & Social
    discord
    
    # Productivity
    obsidian
    thunderbird

    # Dev Tools
    vscode
    neovim
    git
    
    # Utilities
    ethtool
    iw
  ];

  # Example: Managing Git via Home Manager (Optional but cleaner)
  programs.git = {
    enable = true;
    userName = "Shyam";
    userEmail = "shuklashyam@outlook.com";
  };



  # This version typically matches your system version
  home.stateVersion = "24.11";
}
