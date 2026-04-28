# modules/1password.nix
# 1Password CLI + GUI with system-wide polkit/agent integration.
{ config, pkgs, ... }:

{
  programs._1password = { enable = true; };
  
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "shyam" ];
  };
}
