{ config, pkgs, pkgs-unstable, lib, ... }:

{
  imports = [ ../default/home.nix ];

  # --- Device-specific packages ---
  home.packages = lib.mkAfter (with pkgs; [
    thunderbird
  ]);
}
