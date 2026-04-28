# modules/plex.nix
# Plex Media Server. Currently unused by any host but kept for easy reuse.
{ config, pkgs, ... }:
{
services.plex = {
  enable = true;
  openFirewall = true;
};
}