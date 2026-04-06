{ config, pkgs, pkgs-unstable, lib, ... }:

{
  imports = [ ../default/home.nix ];

  # --- Desktop-specific packages ---
  home.packages = lib.mkAfter (with pkgs; [
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
