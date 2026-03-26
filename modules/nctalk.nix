{ config, pkgs-unstable, ... }:
{
environment.systemPackages = [
  pkgs-unstable.nextcloud-talk-desktop
  pkgs-unstable.devenv
];
}