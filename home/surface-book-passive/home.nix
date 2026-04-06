{ config, pkgs, pkgs-unstable, ... }:

{
  imports = [ ../default/home.nix ];

  # --- Device-specific packages ---
  home.packages = (import ../default/home.nix { inherit config pkgs pkgs-unstable; }).home.packages ++ (with pkgs; [
    moonlight-qt
    nodejs_24
    _1password-cli
  ]);
}
