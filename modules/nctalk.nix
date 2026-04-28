# modules/nctalk.nix
# Nextcloud Talk desktop client (from unstable). Currently unused; kept for reuse.
{ config, pkgs-unstable, ... }:
{
environment.systemPackages = [
  pkgs-unstable.nextcloud-talk-desktop
  pkgs-unstable.devenv
];
}