# hosts/default/configuration.nix
# Common configuration shared by all NixOS hosts
{ ... }:

{
  imports = [
    # All hosts share these common modules
    ../../modules/nix-settings.nix
    ../../modules/base.nix
    ../../modules/gnome.nix
    # Note: Audio is host-specific (audio.nix vs audio-laptop.nix)
    # Each host config should import its appropriate audio module
  ];

  # This file provides the baseline configuration.
  # Host-specific configs (in hosts/*/configuration.nix) should:
  # 1. Import this file
  # 2. Add their own hardware configuration
  # 3. Add their own specific modules (audio, GPU, etc.)
}
