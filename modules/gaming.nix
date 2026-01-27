# modules/gaming.nix
{ config, pkgs, pkgs-unstable, ... }:

{
  # 1. Enable Steam (System Level)
  programs.steam = {
    enable = true;
    #remotePlay.openFirewall = true;
  };

  # 2. Gaming Services
  programs.gamemode.enable = true;
  programs.gamescope.enable = true;

  # 3. System-wide Gaming Packages
  environment.systemPackages = [
    # Heroic (Unstable) with overrides for integration
    (pkgs-unstable.heroic.override {
      extraPkgs = p: [ p.gamescope p.mangohud p.gamemode ];
    })
    
    # Wine & Support Tools
    pkgs.wineWowPackages.stable # Essential for 32-bit & 64-bit games
    pkgs.winetricks
    pkgs-unstable.protonup-qt     # To download GE-Proton for Heroic/Steam
    pkgs.nexusmods-app
    pkgs.protontricks
  ];

  # 4. Critical Graphics Settings
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Required for many older/unstable games and Steam
  };
  nixpkgs.config.permittedInsecurePackages = [
   "nexusmods-app-0.21.1"
   ];
}