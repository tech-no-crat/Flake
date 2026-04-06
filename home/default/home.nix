{ config, pkgs, pkgs-unstable, ... }:

{
  home.username = "shyam";
  home.homeDirectory = "/home/shyam";
  
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # --- Common User Packages (shared across all hosts) ---
  home.packages = with pkgs; [
    # Communication / Sync
    nextcloud-client
    
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

  programs.firefox = {
    enable = true;
    profiles.default = {
      isDefault = true;
      # Settings that survive sync and apply before login
      settings = {
        # Sync configuration
        "identity.fxaccounts.enabled" = true;
        # Enable automatic sync login prompt
        "services.sync.autoLogin" = true;
        # UI customizations
        "browser.contentblocking.category" = "strict";
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        # Privacy
        "privacy.trackingprotection.enabled" = true;
      };
    };
  };

  home.stateVersion = "25.05";
}
