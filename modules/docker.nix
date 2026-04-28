# modules/docker.nix
# Docker container runtime
{ config, pkgs, ... }:

{
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  users.users.shyam.extraGroups = [ "docker" ];
}
