{ config, pkgs, pkgs-unstable, ... }:

{
  # Basic User Info
  home.username = "shyam";
  home.homeDirectory = "/home/shyam";
  # Allow unfree packages in Home Manager context
  nixpkgs.config.allowUnfree = true;
  
  # --- User Packages (The "Apps") ---
home.packages = [
    # --- STABLE PACKAGES (from pkgs) ---
    pkgs.obsidian
    pkgs.thunderbird
    pkgs.git
    pkgs.ethtool
    pkgs.iw
    pkgs.nextcloud-client

    # --- UNSTABLE PACKAGES (from pkgs-unstable) ---
    pkgs-unstable.discord    # Discord often breaks on stable if not updated
    pkgs-unstable.vscode     # Get the latest features/extensions
    pkgs-unstable.neovim     # Often desired for latest plugins
  ];

  # Example: Managing Git via Home Manager (Optional but cleaner)
  programs.direnv.enable = true;
  programs.git.enable = true;
  programs.git.settings = {
    user.name = "Shyam";
    user.email = "shuklashyam@outlook.com";
  };



  # This version typically matches your system version
  home.stateVersion = "25.05";
}
