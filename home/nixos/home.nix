{ config, pkgs, pkgs-unstable, ... }:

{
  imports = [ ../default/home.nix ];

  # --- Desktop-specific packages ---
  home.packages = (import ../default/home.nix { inherit config pkgs; }).home.packages ++ (with pkgs; [
    # Communication
    thunderbird
    
    # Network Tools
    ethtool
    iw
    
    # Development
    pkgs-unstable.discord
    pkgs-unstable.vscode
  ]);
}
